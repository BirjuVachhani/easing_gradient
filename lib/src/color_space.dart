import 'dart:math' as math;
import 'dart:ui' show Color, ColorSpace;

import 'package:flutter/foundation.dart' show visibleForTesting;

/// The color space used to calculate intermediate gradient colors.
///
/// A pair of endpoint colors can be connected through several different color
/// paths. The selected path determines the hue, lightness, and chroma seen in
/// the middle of the fade. All inputs are converted to sRGB before mixing, and
/// every result, including an endpoint returned by [mixColors], is an sRGB
/// [Color]. This preserves the endpoint's sRGB appearance, but does not preserve
/// a wide-gamut input's original [Color.colorSpace] or out-of-sRGB gamut.
///
/// [mixColors] alpha-weights the rectangular components before interpolation.
/// In the polar [oklch] and [hsl] spaces, the non-hue components are
/// alpha-weighted while hue follows a separate angular path. A fully
/// transparent chromatic endpoint can therefore still influence the chosen hue
/// path in a polar space.
enum EasingColorSpace {
  /// Plain sRGB, the space Flutter's [Color.lerp] and the built in gradients
  /// use.
  ///
  /// Pick this when opaque endpoints, or endpoints with equal alpha, should
  /// follow the same RGB coordinate path as [Color.lerp] and a plain Flutter
  /// gradient. With differing alpha, [mixColors] uses alpha-weighted components
  /// and intentionally differs from Flutter's straight-RGBA interpolation.
  /// Chromatic sRGB fades can look muddy in the middle.
  srgb,

  /// Linear light RGB, that is sRGB with the display transfer function removed.
  ///
  /// This is how light actually adds up, so it avoids the dark band that plain
  /// sRGB shows between complementary colors. It is the default of
  /// postcss-easing-gradients, so pick it for parity with that tool.
  linearRgb,

  /// OKLab, a perceptually uniform space by Bjorn Ottosson.
  ///
  /// Equal numeric steps are designed to look more like equal visual steps, so
  /// changes in lightness and color usually feel more evenly paced than sRGB.
  /// Vividness still depends on the endpoints, and conversion back to sRGB can
  /// clip colors that fall outside the output gamut. This is the package
  /// default.
  oklab,

  /// OKLCH, the cylindrical form of [oklab] with lightness, chroma, and hue.
  ///
  /// Hue follows the shorter arc around the wheel while lightness and chroma
  /// interpolate directly. This often avoids a gray midpoint, but the final
  /// independent sRGB channel clipping can reduce chroma or alter the rendered
  /// hue of out-of-gamut intermediate colors.
  oklch,

  /// Classic HSL.
  ///
  /// Offered for parity with CSS tooling and for the rainbow style sweeps it
  /// produces. It is not perceptually uniform, so [oklch] is usually the better
  /// choice for hue interpolation.
  hsl,
}

/// A color decomposed into an alpha value plus the three components of some
/// [EasingColorSpace].
///
/// The meaning of [x], [y] and [z] depends on the space:
///
/// * [EasingColorSpace.srgb] and [EasingColorSpace.linearRgb]: red, green, blue
/// * [EasingColorSpace.oklab]: L, a, b
/// * [EasingColorSpace.oklch]: L, C, hue in radians
/// * [EasingColorSpace.hsl]: hue in radians, saturation, lightness
typedef ColorComponents = ({double alpha, double x, double y, double z});

/// Components whose absolute value is below this are treated as achromatic, so
/// their hue is considered powerless and is borrowed from the other endpoint.
///
/// This mirrors the powerless component rules of CSS Color 4.
const double _achromaticEpsilon = 1e-7;

/// Alpha below this is treated as fully transparent when unpremultiplying, to
/// avoid dividing by (almost) zero.
const double _alphaEpsilon = 1e-7;

/// Returns [color] in the sRGB color space, unchanged when it already is.
///
/// Wide-gamut colors (Display P3 for instance) are converted first so all
/// blending math uses one set of primaries that Flutter's gradient shaders can
/// consume consistently. This conversion is lossy when the source color is
/// outside sRGB: the returned [Color] cannot retain those wide-gamut values.
Color toSrgbColor(Color color) => color.colorSpace == ColorSpace.sRGB
    ? color
    : color.withValues(colorSpace: ColorSpace.sRGB);

/// Removes the sRGB transfer function from a single channel, mapping a display
/// encoded value to linear light.
///
/// The sign is mirrored so that values outside `[0, 1]`, which overshooting
/// curves such as `Curves.elasticOut` can produce, keep behaving monotonically
/// instead of folding back on themselves.
@visibleForTesting
double linearizeChannel(double u) {
  final double magnitude = u.abs();
  if (magnitude <= 0.04045) return u / 12.92;
  final double linear = math.pow((magnitude + 0.055) / 1.055, 2.4).toDouble();
  return u.isNegative ? -linear : linear;
}

/// Applies the sRGB transfer function to a single channel, mapping linear light
/// back to a display encoded value. The inverse of [linearizeChannel].
@visibleForTesting
double delinearizeChannel(double u) {
  final double magnitude = u.abs();
  if (magnitude <= 0.0031308) return u * 12.92;
  final double encoded =
      1.055 * math.pow(magnitude, 1 / 2.4).toDouble() - 0.055;
  return u.isNegative ? -encoded : encoded;
}

/// A cube root that preserves the sign of [value], so it is defined for the
/// negative intermediates that out of gamut colors produce.
double _cbrt(double value) {
  if (value == 0) return 0;
  final double root = math.pow(value.abs(), 1 / 3).toDouble();
  return value.isNegative ? -root : root;
}

/// Converts linear light RGB to OKLab.
///
/// Matrices are Bjorn Ottosson's reference values from
/// https://bottosson.github.io/posts/oklab/.
@visibleForTesting
(double, double, double) linearRgbToOklab(double r, double g, double b) {
  final double l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  final double m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  final double s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

  final double lRoot = _cbrt(l);
  final double mRoot = _cbrt(m);
  final double sRoot = _cbrt(s);

  return (
    0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot,
    1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot,
    0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot,
  );
}

/// Converts OKLab back to linear light RGB. The inverse of [linearRgbToOklab].
@visibleForTesting
(double, double, double) oklabToLinearRgb(
  double lightness,
  double a,
  double b,
) {
  final double lRoot = lightness + 0.3963377774 * a + 0.2158037573 * b;
  final double mRoot = lightness - 0.1055613458 * a - 0.0638541728 * b;
  final double sRoot = lightness - 0.0894841775 * a - 1.2914855480 * b;

  final double l = lRoot * lRoot * lRoot;
  final double m = mRoot * mRoot * mRoot;
  final double s = sRoot * sRoot * sRoot;

  return (
    4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
  );
}

/// Converts sRGB components to HSL, with hue in radians.
@visibleForTesting
(double, double, double) srgbToHsl(double r, double g, double b) {
  final double maxChannel = math.max(r, math.max(g, b));
  final double minChannel = math.min(r, math.min(g, b));
  final double lightness = (maxChannel + minChannel) / 2;
  final double delta = maxChannel - minChannel;

  if (delta == 0) return (0, 0, lightness);

  // Guaranteed non zero: delta > 0 forces lightness strictly between 0 and 1.
  final double saturation = delta / (1 - (2 * lightness - 1).abs());

  final double sextant;
  if (maxChannel == r) {
    sextant = ((g - b) / delta) % 6;
  } else if (maxChannel == g) {
    sextant = (b - r) / delta + 2;
  } else {
    sextant = (r - g) / delta + 4;
  }

  return (sextant * (math.pi / 3), saturation, lightness);
}

/// Converts HSL, with hue in radians, back to sRGB. The inverse of [srgbToHsl].
@visibleForTesting
(double, double, double) hslToSrgb(
  double hue,
  double saturation,
  double lightness,
) {
  final double chroma = (1 - (2 * lightness - 1).abs()) * saturation;
  final double sextant = (hue / (math.pi / 3)) % 6;
  final double secondary = chroma * (1 - ((sextant % 2) - 1).abs());
  final double offset = lightness - chroma / 2;

  final (double r, double g, double b) = switch (sextant) {
    < 1 => (chroma, secondary, 0.0),
    < 2 => (secondary, chroma, 0.0),
    < 3 => (0.0, chroma, secondary),
    < 4 => (0.0, secondary, chroma),
    < 5 => (secondary, 0.0, chroma),
    _ => (chroma, 0.0, secondary),
  };

  return (r + offset, g + offset, b + offset);
}

/// Decomposes [color] into the components of [space].
///
/// The color is normalized to sRGB first, see [toSrgbColor].
@visibleForTesting
ColorComponents encodeColor(Color color, EasingColorSpace space) {
  final Color srgb = toSrgbColor(color);
  final double r = srgb.r;
  final double g = srgb.g;
  final double b = srgb.b;
  final double alpha = srgb.a;

  switch (space) {
    case EasingColorSpace.srgb:
      return (alpha: alpha, x: r, y: g, z: b);
    case EasingColorSpace.linearRgb:
      return (
        alpha: alpha,
        x: linearizeChannel(r),
        y: linearizeChannel(g),
        z: linearizeChannel(b),
      );
    case EasingColorSpace.oklab:
      final (double l, double a, double bb) = linearRgbToOklab(
        linearizeChannel(r),
        linearizeChannel(g),
        linearizeChannel(b),
      );
      return (alpha: alpha, x: l, y: a, z: bb);
    case EasingColorSpace.oklch:
      final (double l, double a, double bb) = linearRgbToOklab(
        linearizeChannel(r),
        linearizeChannel(g),
        linearizeChannel(b),
      );
      return (
        alpha: alpha,
        x: l,
        y: math.sqrt(a * a + bb * bb),
        z: math.atan2(bb, a),
      );
    case EasingColorSpace.hsl:
      final (double h, double s, double l) = srgbToHsl(r, g, b);
      return (alpha: alpha, x: h, y: s, z: l);
  }
}

/// Rebuilds an sRGB [Color] from components of [space].
///
/// Conversion finishes in floating point, then alpha and each sRGB channel are
/// clipped independently to `[0, 1]`. Independent clipping is inexpensive and
/// guarantees a valid Flutter [Color], but it is not perceptual gamut mapping:
/// it can change hue, lightness, or chroma. Clipping each generated stop is also
/// why sharp, overshooting, and highly chromatic paths can require more samples
/// than a simple in-gamut fade.
@visibleForTesting
Color decodeColor(ColorComponents components, EasingColorSpace space) {
  final double x = components.x;
  final double y = components.y;
  final double z = components.z;

  final double r;
  final double g;
  final double b;

  switch (space) {
    case EasingColorSpace.srgb:
      (r, g, b) = (x, y, z);
    case EasingColorSpace.linearRgb:
      (r, g, b) = (
        delinearizeChannel(x),
        delinearizeChannel(y),
        delinearizeChannel(z),
      );
    case EasingColorSpace.oklab:
      final (double lr, double lg, double lb) = oklabToLinearRgb(x, y, z);
      (r, g, b) = (
        delinearizeChannel(lr),
        delinearizeChannel(lg),
        delinearizeChannel(lb),
      );
    case EasingColorSpace.oklch:
      final (double lr, double lg, double lb) = oklabToLinearRgb(
        x,
        y * math.cos(z),
        y * math.sin(z),
      );
      (r, g, b) = (
        delinearizeChannel(lr),
        delinearizeChannel(lg),
        delinearizeChannel(lb),
      );
    case EasingColorSpace.hsl:
      (r, g, b) = hslToSrgb(x, y, z);
  }

  return Color.from(
    alpha: components.alpha.clamp(0.0, 1.0),
    red: r.clamp(0.0, 1.0),
    green: g.clamp(0.0, 1.0),
    blue: b.clamp(0.0, 1.0),
  );
}

/// Index of the hue component of [space] within [ColorComponents], or -1 when
/// the space has no hue.
int _hueComponentIndex(EasingColorSpace space) => switch (space) {
  EasingColorSpace.oklch => 2,
  EasingColorSpace.hsl => 0,
  EasingColorSpace.srgb ||
  EasingColorSpace.linearRgb ||
  EasingColorSpace.oklab => -1,
};

/// The component of [space] that decides whether a color is achromatic, and so
/// whether its hue carries any meaning.
double _chromaOf(ColorComponents components, EasingColorSpace space) =>
    switch (space) {
      EasingColorSpace.oklch => components.y,
      EasingColorSpace.hsl => components.y,
      EasingColorSpace.srgb ||
      EasingColorSpace.linearRgb ||
      EasingColorSpace.oklab => 0,
    };

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Interpolates two hues in radians along the shorter way around the wheel.
double _lerpHue(double from, double to, double t) {
  double delta = (to - from) % (2 * math.pi);
  if (delta > math.pi) delta -= 2 * math.pi;
  return from + delta * t;
}

/// Blends [from] and [to] by fraction [t] through [space] and returns an sRGB
/// [Color].
///
/// The algorithm is:
///
/// 1. Convert both inputs to sRGB and encode them in [space].
/// 2. Multiply every non-hue component by its alpha.
/// 3. Interpolate alpha and the premultiplied components by [t]. In
///    [EasingColorSpace.oklch] and [EasingColorSpace.hsl], interpolate hue
///    separately along the shorter angular path.
/// 4. Divide the non-hue components by the interpolated alpha, except near zero
///    where division would be numerically unstable.
/// 5. Convert to sRGB and independently clip alpha and channels to `[0, 1]`.
///
/// This follows the CSS Color 4 premultiplication model for non-hue components,
/// but it is not a complete implementation of CSS missing-component or gamut
/// mapping rules.
///
/// [t] is deliberately not clamped. Elastic and back curves can supply values
/// below zero or above one. Alpha and components are extrapolated first, and
/// only the final sRGB result is clipped. Polar hue extrapolates along the
/// already selected short arc. Clipping may flatten part of a visible
/// overshoot, especially near the sRGB gamut boundary.
///
/// In rectangular spaces this prevents a transparent endpoint's hidden RGB
/// from polluting the visible fade. For example, white fading to transparent
/// black stays white while its alpha decreases. In polar spaces, a transparent
/// chromatic endpoint's hidden hue can still influence the angular hue path.
Color mixColors(Color from, Color to, double t, EasingColorSpace space) {
  // Skip conversion through the chosen interpolation space at endpoints. Input
  // normalization still returns sRGB, so a wide-gamut Color is not identical.
  if (t == 0) return toSrgbColor(from);
  if (t == 1) return toSrgbColor(to);

  final ColorComponents a = encodeColor(from, space);
  final ColorComponents b = encodeColor(to, space);

  final int hueIndex = _hueComponentIndex(space);
  final double alpha = _lerp(a.alpha, b.alpha, t);

  if (hueIndex < 0) {
    // Rectangular space: premultiply all three components.
    final double x = _lerp(a.x * a.alpha, b.x * b.alpha, t);
    final double y = _lerp(a.y * a.alpha, b.y * b.alpha, t);
    final double z = _lerp(a.z * a.alpha, b.z * b.alpha, t);

    if (alpha.abs() <= _alphaEpsilon) {
      // Dividing by nearly zero would amplify floating-point error, especially
      // when an overshooting curve crosses alpha zero. Straight interpolation
      // provides deterministic hidden RGB; at zero alpha it is not visible.
      return decodeColor((
        alpha: alpha,
        x: _lerp(a.x, b.x, t),
        y: _lerp(a.y, b.y, t),
        z: _lerp(a.z, b.z, t),
      ), space);
    }

    return decodeColor((
      alpha: alpha,
      x: x / alpha,
      y: y / alpha,
      z: z / alpha,
    ), space);
  }

  // Polar space: hue interpolates around the wheel and is never premultiplied,
  // matching the CSS Color 4 rules for hue components.
  double hueFrom = hueIndex == 0 ? a.x : a.z;
  double hueTo = hueIndex == 0 ? b.x : b.z;

  final bool fromIsGray = _chromaOf(a, space).abs() <= _achromaticEpsilon;
  final bool toIsGray = _chromaOf(b, space).abs() <= _achromaticEpsilon;
  if (fromIsGray && !toIsGray) {
    hueFrom = hueTo;
  } else if (toIsGray && !fromIsGray) {
    hueTo = hueFrom;
  }

  final double hue = _lerpHue(hueFrom, hueTo, t);

  // The two components that are not the hue, in their natural order.
  final double firstFrom = hueIndex == 0 ? a.y : a.x;
  final double firstTo = hueIndex == 0 ? b.y : b.x;
  final double secondFrom = hueIndex == 0 ? a.z : a.y;
  final double secondTo = hueIndex == 0 ? b.z : b.y;

  double first = _lerp(firstFrom * a.alpha, firstTo * b.alpha, t);
  double second = _lerp(secondFrom * a.alpha, secondTo * b.alpha, t);

  if (alpha.abs() <= _alphaEpsilon) {
    first = _lerp(firstFrom, firstTo, t);
    second = _lerp(secondFrom, secondTo, t);
  } else {
    first /= alpha;
    second /= alpha;
  }

  return decodeColor(
    hueIndex == 0
        ? (alpha: alpha, x: hue, y: first, z: second)
        : (alpha: alpha, x: first, y: second, z: hue),
    space,
  );
}
