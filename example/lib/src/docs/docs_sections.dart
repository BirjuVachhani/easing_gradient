/// Metadata for one docs section: its anchor [id] and display [title].
class DocsSection {
  const DocsSection(this.id, this.title);

  final String id;
  final String title;
}

/// A named group of sections, rendered as one labelled block in the rail.
class DocsSectionGroup {
  const DocsSectionGroup(this.title, this.sections);

  final String title;
  final List<DocsSection> sections;
}

/// The docs, ordered from first use through advanced behavior.
const docsGroups = <DocsSectionGroup>[
  DocsSectionGroup('Getting started', [
    DocsSection('introduction', 'Introduction'),
    DocsSection('installation', 'Installation'),
    DocsSection('quick-start', 'Quick start'),
  ]),
  DocsSectionGroup('Core API', [
    DocsSection('gradients', 'Gradient classes'),
    DocsSection('sampler', 'Low-level sampler'),
    DocsSection('transitions', 'Per-transition curves'),
    DocsSection('steps', 'Hard bands'),
  ]),
  DocsSectionGroup('Color', [
    DocsSection('color-spaces', 'Color spaces'),
    DocsSection('wide-gamut', 'Wide gamut output'),
    DocsSection('transparency', 'Transparency'),
  ]),
  DocsSectionGroup('Rendering', [
    DocsSection('accuracy', 'Accuracy'),
    DocsSection('performance', 'Performance'),
    DocsSection('animation', 'Animation'),
    DocsSection('limitations', 'Limitations'),
  ]),
];

/// The groups flattened into reading order, shared by anchor keys, scroll spy,
/// and the content column.
final docsSections = <DocsSection>[
  for (final group in docsGroups) ...group.sections,
];
