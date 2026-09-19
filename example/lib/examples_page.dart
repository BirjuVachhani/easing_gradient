import 'package:easing_gradient/easing_gradient.dart';
import 'package:flutter/material.dart';

import 'src/theme/tokens.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/code_block.dart';
import 'src/widgets/section.dart';

/// A named palette, rendered as an eased top-to-bottom gradient.
typedef GradientExample = ({String name, List<Color> colors});

// Sampled by eye from the reference screenshots, so these are close
// recreations of the originals rather than exact brand colors.
const webGradientExamples = <GradientExample>[
  (
    name: 'Michelberger rooms',
    colors: [Color(0xFFA78BF0), Color(0xFFEF6373), Color(0xFFF2A25C)],
  ),
  (name: 'Better Half studio', colors: [Color(0xFFE7C468), Color(0xFFF2EEE3)]),
  (
    name: 'Gucci Beauty',
    colors: [Color(0xFFAFD3DB), Color(0xFFB7D6BB), Color(0xFFB3C87F)],
  ),
];

const _pills = <GradientExample>[
  (name: 'Pistachio', colors: [Color(0xFFC9D17E), Color(0xFF66B878)]),
  (name: 'Sage fade', colors: [Color(0xFF83C293), Color(0xFFD6D8D3)]),
  (name: 'Periwinkle', colors: [Color(0xFFC5CFDA), Color(0xFF9678E8)]),
  (name: 'Apricot blush', colors: [Color(0xFFF2A93B), Color(0xFFF5BCB0)]),
  (name: 'Lilac magenta', colors: [Color(0xFFCDB8E4), Color(0xFFEC4D9B)]),
  (name: 'Stone teal', colors: [Color(0xFF7D7B72), Color(0xFFA3C8C4)]),
  (name: 'Sky', colors: [Color(0xFF3E8EE0), Color(0xFFBEE3F0)]),
  (name: 'Mint frost', colors: [Color(0xFFF0FAFA), Color(0xFF6CC5CC)]),
  (name: 'Punch cyan', colors: [Color(0xFFEC4D96), Color(0xFFACE0EC)]),
  (name: 'Seafoam', colors: [Color(0xFFB4E3DE), Color(0xFFDCF6F8)]),
  (name: 'Salmon', colors: [Color(0xFFF2949B), Color(0xFFEE5560)]),
  (name: 'Vermilion', colors: [Color(0xFFE85427), Color(0xFFCE231B)]),
  (name: 'Spearmint', colors: [Color(0xFF6FE3A0), Color(0xFF2E9E82)]),
  (name: 'Lagoon', colors: [Color(0xFF45AFB4), Color(0xFFA8E8E4)]),
  (name: 'Coral rose', colors: [Color(0xFFF2988E), Color(0xFFE4405F)]),
  (name: 'Porcelain tan', colors: [Color(0xFFEAE1DC), Color(0xFFC29775)]),
  (name: 'Caramel', colors: [Color(0xFFD9BA9F), Color(0xFFB0764C)]),
  (name: 'Honey', colors: [Color(0xFFF7DA8A), Color(0xFFF09A4C)]),
  (name: 'Amber', colors: [Color(0xFFEFC257), Color(0xFFB58024)]),
  (name: 'Taupe', colors: [Color(0xFFC9BEBD), Color(0xFF9A9494)]),
];

// Every background gradient from the pluto new-tab project,
// lib/resources/color_gradients.dart.
const _pluto = <GradientExample>[
  (name: 'YouTube', colors: [Color(0xFFE52D27), Color(0xFFB31217)]),
  (name: 'Cool Brown', colors: [Color(0xFF603813), Color(0xFFB29F94)]),
  (name: 'Harmonic Energy', colors: [Color(0xFF16A085), Color(0xFFF4D03F)]),
  (name: 'Playing with Reds', colors: [Color(0xFFD31027), Color(0xFFEA384D)]),
  (name: 'Sunny Days', colors: [Color(0xFFEDE574), Color(0xFFE1F5C4)]),
  (name: 'Green Beach', colors: [Color(0xFF02AAB0), Color(0xFF00CDAC)]),
  (name: 'Intuitive Purple', colors: [Color(0xFFDA22FF), Color(0xFF9733EE)]),
  (name: 'Emerald Water', colors: [Color(0xFF348F50), Color(0xFF56B4D3)]),
  (name: 'Lemon Twist', colors: [Color(0xFF3CA55C), Color(0xFFB5AC49)]),
  (name: 'Horizon', colors: [Color(0xFF003973), Color(0xFFE5E5BE)]),
  (name: 'Rose Water', colors: [Color(0xFFE55D87), Color(0xFF5FC3E4)]),
  (name: 'Frozen', colors: [Color(0xFF403B4A), Color(0xFFE7E9BB)]),
  (name: 'Mango Pulp', colors: [Color(0xFFF09819), Color(0xFFEDDE5D)]),
  (name: 'Bloody Mary', colors: [Color(0xFFFF512F), Color(0xFFDD2476)]),
  (name: 'Aubergine', colors: [Color(0xFFAA076B), Color(0xFF61045F)]),
  (name: 'Aqua Marine', colors: [Color(0xFF1A2980), Color(0xFF26D0CE)]),
  (name: 'Sunrise', colors: [Color(0xFFFF512F), Color(0xFFF09819)]),
  (name: 'Purple Paradise', colors: [Color(0xFF1D2B64), Color(0xFFF8CDDA)]),
  (name: 'Sea Weed', colors: [Color(0xFF4CB8C4), Color(0xFF3CD3AD)]),
  (name: 'Pinky', colors: [Color(0xFFDD5E89), Color(0xFFF7BB97)]),
  (name: 'Cherry', colors: [Color(0xFFEB3349), Color(0xFFF45C43)]),
  (name: 'Mojito', colors: [Color(0xFF1D976C), Color(0xFF93F9B9)]),
  (name: 'Juicy Orange', colors: [Color(0xFFFF8008), Color(0xFFFFC837)]),
  (name: 'Mirage', colors: [Color(0xFF16222A), Color(0xFF3A6073)]),
  (name: 'Steel Gray', colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)]),
  (name: 'Kashmir', colors: [Color(0xFF614385), Color(0xFF516395)]),
  (name: 'Electric Violet', colors: [Color(0xFF4776E6), Color(0xFF8E54E9)]),
  (name: 'Venice Blue', colors: [Color(0xFF085078), Color(0xFF85D8CE)]),
  (name: 'Bora Bora', colors: [Color(0xFF2BC0E4), Color(0xFFEAECC6)]),
  (name: 'Moss', colors: [Color(0xFF134E5E), Color(0xFF71B280)]),
  (name: 'Shroom Haze', colors: [Color(0xFF5C258D), Color(0xFF4389A2)]),
  (name: 'Mystic', colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)]),
  (name: 'Midnight City', colors: [Color(0xFF232526), Color(0xFF414345)]),
  (name: 'Sea Blizz', colors: [Color(0xFF1CD8D2), Color(0xFF93EDC7)]),
  (name: 'Opa', colors: [Color(0xFF3D7EAA), Color(0xFFFFE47A)]),
  (name: 'Titanium', colors: [Color(0xFF283048), Color(0xFF859398)]),
  (name: 'Mantle', colors: [Color(0xFF24C6DC), Color(0xFF514A9D)]),
  (name: 'Dracula', colors: [Color(0xFFDC2424), Color(0xFF4A569D)]),
  (name: 'Peach', colors: [Color(0xFFED4264), Color(0xFFFFEDBC)]),
  (name: 'Moonrise', colors: [Color(0xFFDAE2F8), Color(0xFFD6A4A4)]),
  (name: 'Clouds', colors: [Color(0xFFECE9E6), Color(0xFFFFFFFF)]),
  (name: 'Stellar', colors: [Color(0xFF7474BF), Color(0xFF348AC7)]),
  (name: 'Bourbon', colors: [Color(0xFFEC6F66), Color(0xFFF3A183)]),
  (name: 'Calm Darya', colors: [Color(0xFF5F2C82), Color(0xFF49A09D)]),
  (name: 'Influenza', colors: [Color(0xFFC04848), Color(0xFF480048)]),
  (name: 'Shrimpy', colors: [Color(0xFFE43A15), Color(0xFFE65245)]),
  (name: 'Army', colors: [Color(0xFF414D0B), Color(0xFF727A17)]),
  (name: 'Miaka', colors: [Color(0xFFFC354C), Color(0xFF0ABFBC)]),
  (name: 'Pinot Noir', colors: [Color(0xFF4B6CB7), Color(0xFF182848)]),
  (name: 'Day Tripper', colors: [Color(0xFFF857A6), Color(0xFFFF5858)]),
  (name: 'Namn', colors: [Color(0xFFA73737), Color(0xFF7A2828)]),
  (name: 'Blurry Beach', colors: [Color(0xFFD53369), Color(0xFFCBAD6D)]),
  (name: 'Vasily', colors: [Color(0xFFE9D362), Color(0xFF333333)]),
  (name: 'A Lost Memory', colors: [Color(0xFFDE6262), Color(0xFFFFB88C)]),
  (name: 'Petrichor', colors: [Color(0xFF666600), Color(0xFF999966)]),
  (name: 'Jonquil', colors: [Color(0xFFFFEEEE), Color(0xFFDDEFBB)]),
  (name: 'Sirius Tamed', colors: [Color(0xFFEFEFBB), Color(0xFFD4D3DD)]),
  (name: 'Kyoto', colors: [Color(0xFFC21500), Color(0xFFFFC500)]),
  (name: 'Misty Meadow', colors: [Color(0xFF215F00), Color(0xFFE4E4D9)]),
  (name: 'Aqualicious', colors: [Color(0xFF50C9C3), Color(0xFF96DEDA)]),
  (name: 'Moor', colors: [Color(0xFF616161), Color(0xFF9BC5C3)]),
  (name: 'Almost', colors: [Color(0xFFDDD6F3), Color(0xFFFAACA8)]),
  (name: 'Forever Lost', colors: [Color(0xFF5D4157), Color(0xFFA8CABA)]),
  (name: 'Winter', colors: [Color(0xFFE6DADA), Color(0xFF274046)]),
  (name: 'Autumn', colors: [Color(0xFFDAD299), Color(0xFFB0DAB9)]),
  (name: 'Candy', colors: [Color(0xFFD3959B), Color(0xFFBFE6BA)]),
  (name: 'Reef', colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)]),
  (name: 'The Strain', colors: [Color(0xFF870000), Color(0xFF190A05)]),
  (name: 'Dirty Fog', colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)]),
  (name: 'Earthly', colors: [Color(0xFF649173), Color(0xFFDBD5A4)]),
  (name: 'Virgin', colors: [Color(0xFFC9FFBF), Color(0xFFFFAFBD)]),
  (name: 'Ash', colors: [Color(0xFF606C88), Color(0xFF3F4C6B)]),
  (name: 'Shadow Night', colors: [Color(0xFF000000), Color(0xFF53346D)]),
  (name: 'Cherryblossoms', colors: [Color(0xFFFBD3E9), Color(0xFFBB377D)]),
  (name: 'Parklife', colors: [Color(0xFFADD100), Color(0xFF7B920A)]),
  (name: 'Dance To Forget', colors: [Color(0xFFFF4E50), Color(0xFFF9D423)]),
  (name: 'Starfall', colors: [Color(0xFFF0C27B), Color(0xFF4B1248)]),
  (name: 'Red Mist', colors: [Color(0xFF000000), Color(0xFFE74C3C)]),
  (name: 'Teal Love', colors: [Color(0xFFAAFFA9), Color(0xFF11FFBD)]),
  (name: 'Neon Life', colors: [Color(0xFFB3FFAB), Color(0xFF12FFF7)]),
  (name: 'Man of Steel', colors: [Color(0xFF780206), Color(0xFF061161)]),
  (name: 'Amethyst', colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)]),
  (name: 'Cheer Up Emo Kid', colors: [Color(0xFF556270), Color(0xFFFF6B6B)]),
  (name: 'Shore', colors: [Color(0xFF70E1F5), Color(0xFFFFD194)]),
  (name: 'Facebook Messenger', colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
  (name: 'SoundCloud', colors: [Color(0xFFFE8C00), Color(0xFFF83600)]),
  (name: 'Behongo', colors: [Color(0xFF52C234), Color(0xFF061700)]),
  (name: 'ServQuick', colors: [Color(0xFF485563), Color(0xFF29323C)]),
  (name: 'Friday', colors: [Color(0xFF83A4D4), Color(0xFFB6FBFF)]),
  (name: 'Martini', colors: [Color(0xFFFDFC47), Color(0xFF24FE41)]),
  (name: 'Metallic Toad', colors: [Color(0xFFABBAAB), Color(0xFFFFFFFF)]),
  (name: 'Between The Clouds', colors: [Color(0xFF73C8A9), Color(0xFF373B44)]),
  (name: 'Crazy Orange I', colors: [Color(0xFFD38312), Color(0xFFA83279)]),
  (name: 'Hersheys', colors: [Color(0xFF1E130C), Color(0xFF9A8478)]),
  (name: 'Talking To Mice Elf', colors: [Color(0xFF948E99), Color(0xFF2E1437)]),
  (name: 'Purple Bliss', colors: [Color(0xFF360033), Color(0xFF0B8793)]),
  (name: 'Predawn', colors: [Color(0xFFFFA17F), Color(0xFF00223E)]),
  (name: 'Endless River', colors: [Color(0xFF43CEA2), Color(0xFF185A9D)]),
  (
    name: 'Pastel Orange at the Sun',
    colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
  ),
  (name: 'Twitch', colors: [Color(0xFF6441A5), Color(0xFF2A0845)]),
  (name: 'Instagram', colors: [Color(0xFF517FA4), Color(0xFF243949)]),
  (name: 'Flickr', colors: [Color(0xFFFF0084), Color(0xFF33001B)]),
  (name: 'Vine', colors: [Color(0xFF00BF8F), Color(0xFF001510)]),
  (name: 'Turquoise flow', colors: [Color(0xFF136A8A), Color(0xFF267871)]),
  (name: 'Portrait', colors: [Color(0xFF8E9EAB), Color(0xFFEEF2F3)]),
  (name: 'Virgin America', colors: [Color(0xFF7B4397), Color(0xFFDC2430)]),
  (name: 'Koko Caramel', colors: [Color(0xFFD1913C), Color(0xFFFFD194)]),
  (name: 'Fresh Turboscent', colors: [Color(0xFFF1F2B5), Color(0xFF135058)]),
  (name: 'Green to dark', colors: [Color(0xFF6A9113), Color(0xFF141517)]),
  (name: 'Ukraine', colors: [Color(0xFF004FF9), Color(0xFFFFF94C)]),
  (name: 'Curiosity blue', colors: [Color(0xFF525252), Color(0xFF3D72B4)]),
  (name: 'Dark Knight', colors: [Color(0xFFBA8B02), Color(0xFF181818)]),
  (name: 'Piglet', colors: [Color(0xFFEE9CA7), Color(0xFFFFDDE1)]),
  (name: 'Lizard', colors: [Color(0xFF304352), Color(0xFFD7D2CC)]),
  (name: 'Sage Persuasion', colors: [Color(0xFFCCCCB2), Color(0xFF757519)]),
  (
    name: 'Between Night and Day',
    colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
  ),
  (name: 'Timber', colors: [Color(0xFFFC00FF), Color(0xFF00DBDE)]),
  (name: 'Passion', colors: [Color(0xFFE53935), Color(0xFFE35D5B)]),
  (name: 'Clear Sky', colors: [Color(0xFF005C97), Color(0xFF363795)]),
  (name: 'Master Card', colors: [Color(0xFFF46B45), Color(0xFFEEA849)]),
  (name: 'Back To Earth', colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)]),
  (name: 'Deep Purple', colors: [Color(0xFF673AB7), Color(0xFF512DA8)]),
  (name: 'Little Leaf', colors: [Color(0xFF76B852), Color(0xFF8DC26F)]),
  (name: 'Netflix', colors: [Color(0xFF8E0E00), Color(0xFF1F1C18)]),
  (name: 'Light Orange', colors: [Color(0xFFFFB75E), Color(0xFFED8F03)]),
  (name: 'Green and Blue', colors: [Color(0xFFC2E59C), Color(0xFF64B3F4)]),
  (name: 'Poncho', colors: [Color(0xFF403A3E), Color(0xFFBE5869)]),
  (name: 'Back to the Future', colors: [Color(0xFFC02425), Color(0xFFF0CB35)]),
  (name: 'Blush', colors: [Color(0xFFB24592), Color(0xFFF15F79)]),
  (name: 'Inbox', colors: [Color(0xFF457FCA), Color(0xFF5691C8)]),
  (name: 'Purplin', colors: [Color(0xFF6A3093), Color(0xFFA044FF)]),
  (name: 'Pale Wood', colors: [Color(0xFFEACDA3), Color(0xFFD6AE7B)]),
  (name: 'Haikus', colors: [Color(0xFFFD746C), Color(0xFFFF9068)]),
  (name: 'Pizelex', colors: [Color(0xFF114357), Color(0xFFF29492)]),
  (name: 'Joomla', colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
  (name: 'Christmas', colors: [Color(0xFF2F7336), Color(0xFFAA3A38)]),
  (name: 'Minnesota Vikings', colors: [Color(0xFF5614B0), Color(0xFFDBD65C)]),
  (name: 'Miami Dolphins', colors: [Color(0xFF4DA0B0), Color(0xFFD39D38)]),
  (name: 'Forest', colors: [Color(0xFF5A3F37), Color(0xFF2C7744)]),
  (name: 'Nighthawk', colors: [Color(0xFF2980B9), Color(0xFF2C3E50)]),
  (name: 'Superman', colors: [Color(0xFF0099F7), Color(0xFFF11712)]),
  (name: 'Suzy', colors: [Color(0xFF834D9B), Color(0xFFD04ED6)]),
  (name: 'Dark Skies', colors: [Color(0xFF4B79A1), Color(0xFF283E51)]),
  (name: 'Deep Space', colors: [Color(0xFF000000), Color(0xFF434343)]),
  (name: 'Decent', colors: [Color(0xFF4CA1AF), Color(0xFFC4E0E5)]),
  (name: 'Colors Of Sky', colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)]),
  (name: 'Purple White', colors: [Color(0xFFBA5370), Color(0xFFF4E2D8)]),
  (name: 'Ali', colors: [Color(0xFFFF4B1F), Color(0xFF1FDDFF)]),
  (name: 'Alihossein', colors: [Color(0xFFF7FF00), Color(0xFFDB36A4)]),
  (name: 'Shahabi', colors: [Color(0xFFA80077), Color(0xFF66FF00)]),
  (name: 'Red Ocean', colors: [Color(0xFF1D4350), Color(0xFFA43931)]),
  (name: 'Tranquil', colors: [Color(0xFFEECDA3), Color(0xFFEF629F)]),
  (name: 'Transfile', colors: [Color(0xFF16BFFD), Color(0xFFCB3066)]),
  (name: 'Sylvia', colors: [Color(0xFFFF4B1F), Color(0xFFFF9068)]),
  (name: 'Sweet Morning', colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)]),
  (name: 'Politics', colors: [Color(0xFF2196F3), Color(0xFFF44336)]),
  (name: 'Bright Vault', colors: [Color(0xFF00D2FF), Color(0xFF928DAB)]),
  (name: 'Solid Vault', colors: [Color(0xFF3A7BD5), Color(0xFF3A6073)]),
  (name: 'Sunset', colors: [Color(0xFF0B486B), Color(0xFFF56217)]),
  (name: 'Grapefruit Sunset', colors: [Color(0xFFE96443), Color(0xFF904E95)]),
  (name: 'Deep Sea Space', colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
  (name: 'Dusk', colors: [Color(0xFFFFD89B), Color(0xFF19547B)]),
  (name: 'Minimal Red', colors: [Color(0xFFF00000), Color(0xFFDC281E)]),
  (name: 'Royal', colors: [Color(0xFF141E30), Color(0xFF243B55)]),
  (name: 'Mauve', colors: [Color(0xFF42275A), Color(0xFF734B6D)]),
  (name: 'Frost', colors: [Color(0xFF000428), Color(0xFF004E92)]),
  (name: 'Lush', colors: [Color(0xFF56AB2F), Color(0xFFA8E063)]),
  (name: 'Firewatch', colors: [Color(0xFFCB2D3E), Color(0xFFEF473A)]),
  (name: 'Sherbert', colors: [Color(0xFFF79D00), Color(0xFF64F38C)]),
  (name: 'Blood Red', colors: [Color(0xFFF85032), Color(0xFFE73827)]),
  (name: '50 Shades of Grey', colors: [Color(0xFFBDC3C7), Color(0xFF2C3E50)]),
  (name: 'Dania', colors: [Color(0xFFBE93C5), Color(0xFF7BC6CC)]),
  (name: 'Limeade', colors: [Color(0xFFA1FFCE), Color(0xFFFAFFD1)]),
  (name: 'Disco', colors: [Color(0xFF4ECDC4), Color(0xFF556270)]),
  (name: 'Love Couple', colors: [Color(0xFF3A6186), Color(0xFF89253E)]),
  (name: 'Azure Pop', colors: [Color(0xFFEF32D9), Color(0xFF89FFFD)]),
  (name: 'Blade Runner', colors: [Color(0xFF000000), Color(0xFF333333)]),
];

/// Recreations of favorite gradients, all painted with [EasingLinearGradient].
///
/// Each swatch is the same two or three source colors a plain [LinearGradient]
/// would take, so the page doubles as a visual regression surface: a change in
/// sampling or color math shows up across 200 fades at once.
class ExamplesPage extends StatelessWidget {
  const ExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return SelectionArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Section(
              top: AppLayout.navHeight + (compact ? 40 : 64),
              bottom: 0,
              child: const PageHeading(
                title: 'Examples',
                subtitle:
                    'Gradients worth stealing, rebuilt with EasingLinearGradient. '
                    'Every swatch fades top to bottom through Curves.easeInOut '
                    'in OKLab, the package defaults.',
              ),
            ),
            Section(
              top: 40,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading(
                    title: 'From the web',
                    subtitle:
                        'Palettes lifted from sites with a gradient as the '
                        'whole page background.',
                  ),
                  const SizedBox(height: 24),
                  _HeroGrid(examples: webGradientExamples),
                ],
              ),
            ),
            Section(
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeading(
                    title: 'Palette boards',
                    subtitle:
                        'Two reference boards of small two-color fades, the '
                        'kind used for chips, avatars, and cards.',
                  ),
                  const SizedBox(height: 24),
                  _PillBoard(examples: _pills),
                ],
              ),
            ),
            Section(
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeading(
                    title: 'Pluto collection',
                    subtitle:
                        'All ${_pluto.length} background gradients from the pluto '
                        'new-tab project, eased instead of linear.',
                  ),
                  const SizedBox(height: 24),
                  _PillBoard(examples: _pluto),
                ],
              ),
            ),
            const SizedBox(height: 72),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }
}

/// The three full-bleed website recreations, side by side when there is room.
class _HeroGrid extends StatelessWidget {
  const _HeroGrid({required this.examples});

  final List<GradientExample> examples;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 20.0;
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final example in examples)
              SizedBox(
                width: width,
                child: _HeroCard(example: example),
              ),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.example});

  final GradientExample example;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GradientTapTarget(
          example: example,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: colors.border),
                gradient: EasingLinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: example.colors,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          example.name,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          example.colors.map((color) => _hex(color)).join('  '),
          style: TextStyle(
            color: colors.mutedForeground,
            fontFamily: AppFonts.mono,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

/// A board of capsule swatches, mirroring the reference palette images.
class _PillBoard extends StatelessWidget {
  const _PillBoard({required this.examples});

  final List<GradientExample> examples;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 22,
        children: [for (final example in examples) _Pill(example: example)],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.example});

  final GradientExample example;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: 'Show code  ·  ${example.colors.map(_hex).join('  ')}',
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            _GradientTapTarget(
              example: example,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  gradient: EasingLinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: example.colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              example.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedForeground,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats a color as the `#RRGGBB` string a designer would paste back.
String _hex(Color color) {
  return '#${_channel(color.r)}${_channel(color.g)}${_channel(color.b)}';
}

/// Formats a color as the `0xAARRGGBB` literal a Dart snippet would contain.
String _argb(Color color) {
  return '0x${_channel(color.a)}${_channel(color.r)}'
      '${_channel(color.g)}${_channel(color.b)}';
}

String _channel(double value) => (value * 255)
    .round()
    .clamp(0, 255)
    .toRadixString(16)
    .padLeft(2, '0')
    .toUpperCase();

/// Opens the palette and source for one example.
void _showGradientCode(BuildContext context, GradientExample example) {
  showDialog<void>(
    context: context,
    builder: (context) => _GradientCodeDialog(example: example),
  );
}

/// The palette above its source, so a gradient can be read and taken in one
/// place rather than transcribed from a swatch.
class _GradientCodeDialog extends StatelessWidget {
  const _GradientCodeDialog({required this.example});

  final GradientExample example;

  String get _snippet {
    final buffer = StringBuffer()
      ..writeln('EasingLinearGradient(')
      ..writeln('  begin: Alignment.topCenter,')
      ..writeln('  end: Alignment.bottomCenter,')
      ..writeln('  colors: const [');
    for (final color in example.colors) {
      buffer.writeln('    Color(${_argb(color)}),');
    }
    return (buffer
          ..writeln('  ],')
          ..write(')'))
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Dialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      example.name,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PaletteBar(colors: example.colors),
              const SizedBox(height: 20),
              CodeBlock(code: _snippet, filename: 'gradient.dart'),
            ],
          ),
        ),
      ),
    );
  }
}

/// The source colors as one horizontal bar, each segment labelled with its hex.
class _PaletteBar extends StatelessWidget {
  const _PaletteBar({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox(
            height: 64,
            child: Row(
              // Stretch, because a childless ColoredBox takes the smallest
              // height it is offered and a centered row offers it zero.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final color in colors)
                  Expanded(child: ColoredBox(color: color)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final color in colors)
              Expanded(
                child: Text(
                  _hex(color),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.mutedForeground,
                    fontFamily: AppFonts.mono,
                    fontSize: 11.5,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Makes a swatch open [_showGradientCode], with a pointer cursor on hover.
class _GradientTapTarget extends StatelessWidget {
  const _GradientTapTarget({required this.example, required this.child});

  final GradientExample example;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showGradientCode(context, example),
          child: child,
        ),
      ),
    );
  }
}
