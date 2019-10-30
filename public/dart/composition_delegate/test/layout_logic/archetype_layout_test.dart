import 'package:composition_delegate/composition_delegate.dart';
import 'package:test/test.dart';

void main() {
  const Size kLayoutSize = Size(1280, 800);
  const double kMinWidth = 320;
  const double kMinHeight = 320;
  CompositionDelegate setupCompositionDelegate() {
    CompositionDelegate compDelegate = CompositionDelegate(
      layoutContext: LayoutContext(
        size: kLayoutSize,
        minSurfaceWidth: kMinWidth,
        minSurfaceHeight: kMinHeight,
      ),
    )..setLayoutStrategy(layoutStrategy: layoutStrategyType.archetypeStrategy);
    return compDelegate;
  }

  group('Workspace Archetype Test', () {
    test('Primary Alone', () {
      CompositionDelegate compDelegate = setupCompositionDelegate()
        ..addSurface(
          surface: Surface(
            surfaceId: 'primary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'primary',
            },
          ),
        )
        ..focusSurface(surfaceId: 'primary');
      List<Layer> expectedLayout = <Layer>[
        Layer(
            element: SurfaceLayout(
                x: 0.0,
                y: 0.0,
                w: kLayoutSize.width,
                h: kLayoutSize.height,
                surfaceId: 'primary'))
      ];
      expect(compDelegate.getLayout(), equals(expectedLayout));
    });
    test('auxiliary is classified correctly', () {});
    test('Primary, auxiliary parent', () {
      CompositionDelegate compDelegate = setupCompositionDelegate()
        ..addSurface(
          surface: Surface(
            surfaceId: 'primary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'primary',
            },
          ),
        )
        ..focusSurface(surfaceId: 'primary')
        ..addSurface(
          surface: Surface(
            surfaceId: 'auxiliary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'auxiliary',
              'hierarchy': 'parent',
            },
          ),
          parentId: 'primary',
        )
        ..focusSurface(surfaceId: 'auxiliary');
      List<Layer> expectedLayout = <Layer>[
        Layer.fromList(elements: [
          SurfaceLayout(
              x: 0.0,
              y: 0.0,
              w: kLayoutSize.width * 0.2,
              h: kLayoutSize.height,
              surfaceId: 'auxiliary'),
          SurfaceLayout(
              x: kLayoutSize.width * 0.2,
              y: 0.0,
              w: kLayoutSize.width * 0.8,
              h: kLayoutSize.height,
              surfaceId: 'primary'),
        ])
      ];

      expect(compDelegate.getLayout(), equals(expectedLayout));
    });
    test('Primary, auxiliary child', () {
      CompositionDelegate compDelegate = setupCompositionDelegate()
        ..addSurface(
          surface: Surface(
            surfaceId: 'primary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'primary',
            },
          ),
        )
        ..focusSurface(surfaceId: 'primary')
        ..addSurface(
          surface: Surface(
            surfaceId: 'auxiliary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'auxiliary',
              'hierarchy': 'child',
            },
          ),
          parentId: 'primary',
        )
        ..focusSurface(surfaceId: 'primary');
      List<Layer> expectedLayout = <Layer>[
        Layer.fromList(elements: [
          SurfaceLayout(
              x: 0.0,
              y: 0.0,
              w: kLayoutSize.width * 0.8,
              h: kLayoutSize.height,
              surfaceId: 'primary'),
          SurfaceLayout(
              x: kLayoutSize.width * 0.8,
              y: 0.0,
              w: kLayoutSize.width * 0.2,
              h: kLayoutSize.height,
              surfaceId: 'auxiliary'),
        ])
      ];
      expect(compDelegate.getLayout(), equals(expectedLayout));
    });
    test('Primary, auxiliary parent, auxiliary child', () {
      CompositionDelegate compDelegate = setupCompositionDelegate()
        ..addSurface(
          surface: Surface(
            surfaceId: 'primary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'primary',
            },
          ),
        )
        ..focusSurface(surfaceId: 'primary')
        ..addSurface(
          surface: Surface(
            surfaceId: 'auxiliary_l',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'auxiliary',
              'hierarchy': 'parent',
            },
          ),
          parentId: 'primary',
        )
        ..focusSurface(surfaceId: 'auxiliary_l')
        ..addSurface(
          surface: Surface(
            surfaceId: 'auxiliary_r',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'auxiliary',
              'hierarchy': 'child',
            },
          ),
          parentId: 'primary',
        )
        ..focusSurface(surfaceId: 'auxiliary_r');
      List<Layer> expectedLayout = <Layer>[
        Layer.fromList(elements: [
          SurfaceLayout(
              x: 0.0,
              y: 0.0,
              w: kLayoutSize.width * 0.2,
              h: kLayoutSize.height,
              surfaceId: 'auxiliary_l'),
          SurfaceLayout(
              x: kLayoutSize.width * 0.2,
              y: 0.0,
              w: kLayoutSize.width * 0.6,
              h: kLayoutSize.height,
              surfaceId: 'primary'),
          SurfaceLayout(
              x: kLayoutSize.width * 0.8,
              y: 0.0,
              w: kLayoutSize.width * 0.2,
              h: kLayoutSize.height,
              surfaceId: 'auxiliary_r'),
        ])
      ];
      expect(compDelegate.getLayout(), equals(expectedLayout));
    });

    test('Primary, two secondaries, default: copresent', () {
      CompositionDelegate compDelegate = setupCompositionDelegate()
        ..addSurface(
          surface: Surface(
            surfaceId: 'primary',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'primary',
            },
          ),
        )
        ..focusSurface(surfaceId: 'primary')
        ..addSurface(
          surface: Surface(
            surfaceId: 'auxiliary_1',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'auxiliary',
            },
          ),
          relation: SurfaceRelation(arrangement: SurfaceArrangement.copresent),
          parentId: 'primary',
        )
        ..focusSurface(surfaceId: 'auxiliary_1')
        ..addSurface(
          surface: Surface(
            surfaceId: 'auxiliary_2',
            metadata: {
              'archetype': 'workspace',
              'archetype_role': 'auxiliary',
            },
          ),
          relation: SurfaceRelation(arrangement: SurfaceArrangement.copresent),
          parentId: 'primary',
        )
        ..focusSurface(surfaceId: 'auxiliary_2');
      List<Layer> expectedLayout = <Layer>[
        Layer.fromList(elements: [
          SurfaceLayout(
              x: 0.0,
              y: 0.0,
              w: kLayoutSize.width * 0.8,
              h: kLayoutSize.height,
              surfaceId: 'primary'),
          SurfaceLayout(
              x: kLayoutSize.width * 0.8,
              y: 0.0,
              w: kLayoutSize.width * 0.2,
              h: kLayoutSize.height / 2.0,
              surfaceId: 'auxiliary_1'),
          SurfaceLayout(
              x: kLayoutSize.width * 0.8,
              y: kLayoutSize.height / 2.0,
              w: kLayoutSize.width * 0.2,
              h: kLayoutSize.height / 2.0,
              surfaceId: 'auxiliary_2'),
        ])
      ];
      expect(compDelegate.getLayout(), equals(expectedLayout));
    });
  });

  test('Primary, two secondaries, grouping single', () {
    CompositionDelegate compDelegate = setupCompositionDelegate()
      ..addSurface(
        surface: Surface(
          surfaceId: 'primary',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'primary',
          },
        ),
      )
      ..focusSurface(surfaceId: 'primary')
      ..addSurface(
        surface: Surface(
          surfaceId: 'auxiliary_1',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'auxiliary',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'auxiliary_1')
      ..addSurface(
        surface: Surface(
          surfaceId: 'auxiliary_2',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'auxiliary',
            'grouping': 'single',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'auxiliary_2');
    List<Layer> expectedLayout = <Layer>[
      Layer.fromList(elements: [
        SurfaceLayout(
            x: 0.0,
            y: 0.0,
            w: kLayoutSize.width * 0.8,
            h: kLayoutSize.height,
            surfaceId: 'primary'),
        StackLayout(
          x: kLayoutSize.width * 0.8,
          y: 0.0,
          w: kLayoutSize.width * 0.2,
          h: kLayoutSize.height,
          surfaceStack: ['auxiliary_1', 'auxiliary_2'],
        ),
      ])
    ];
    expect(compDelegate.getLayout(), equals(expectedLayout));
  });

  test('Primary, two secondaries, grouping toggle', () {
    CompositionDelegate compDelegate = setupCompositionDelegate()
      ..addSurface(
        surface: Surface(
          surfaceId: 'primary',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'primary',
          },
        ),
      )
      ..focusSurface(surfaceId: 'primary')
      ..addSurface(
        surface: Surface(
          surfaceId: 'auxiliary_1',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'auxiliary',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'auxiliary_1')
      ..addSurface(
        surface: Surface(
          surfaceId: 'auxiliary_2',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'auxiliary',
            'grouping': 'toggle',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'auxiliary_2');
    List<Layer> expectedLayout = <Layer>[
      Layer.fromList(elements: [
        SurfaceLayout(
            x: 0.0,
            y: 0.0,
            w: kLayoutSize.width * 0.8,
            h: kLayoutSize.height,
            surfaceId: 'primary'),
        ToggleableLayout(
          x: kLayoutSize.width * 0.8,
          y: 0.0,
          w: kLayoutSize.width * 0.2,
          h: kLayoutSize.height,
          toggleStack: ['auxiliary_1', 'auxiliary_2'],
        ),
      ])
    ];
    expect(compDelegate.getLayout(), equals(expectedLayout));
  });

  test('Primary, header', () {
    CompositionDelegate compdel = setupCompositionDelegate()
      ..addSurface(
        surface: Surface(
          surfaceId: 'primary',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'primary',
          },
        ),
      )
      ..focusSurface(surfaceId: 'primary')
      ..addSurface(
        surface: Surface(
          surfaceId: 'header',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'header',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'header');
    List<Layer> expectedLayout = <Layer>[
      Layer.fromList(elements: [
        SurfaceLayout(
            x: 0.0,
            y: 0.0,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.1,
            surfaceId: 'header'),
        SurfaceLayout(
            x: 0.0,
            y: kLayoutSize.height * 0.1,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.9,
            surfaceId: 'primary'),
      ])
    ];
    expect(compdel.getLayout(), equals(expectedLayout));
  });

  test('Primary, footer', () {
    CompositionDelegate compdel = setupCompositionDelegate()
      ..addSurface(
        surface: Surface(
          surfaceId: 'primary',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'primary',
          },
        ),
      )
      ..focusSurface(surfaceId: 'primary')
      ..addSurface(
        surface: Surface(
          surfaceId: 'footer',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'footer',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'footer');
    List<Layer> expectedLayout = <Layer>[
      Layer.fromList(elements: [
        SurfaceLayout(
            x: 0.0,
            y: 0.0,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.9,
            surfaceId: 'primary'),
        SurfaceLayout(
            x: 0.0,
            y: kLayoutSize.height * 0.9,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.1,
            surfaceId: 'footer'),
      ])
    ];
    expect(compdel.getLayout(), equals(expectedLayout));
  });

  test('Primary, header, footer', () {
    CompositionDelegate compdel = setupCompositionDelegate()
      ..addSurface(
        surface: Surface(
          surfaceId: 'primary',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'primary',
          },
        ),
      )
      ..focusSurface(surfaceId: 'primary')
      ..addSurface(
        surface: Surface(
          surfaceId: 'header',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'header',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'header')
      ..addSurface(
        surface: Surface(
          surfaceId: 'footer',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'footer',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'footer');
    List<Layer> expectedLayout = <Layer>[
      Layer.fromList(elements: [
        SurfaceLayout(
            x: 0.0,
            y: 0.0,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.1,
            surfaceId: 'header'),
        SurfaceLayout(
            x: 0.0,
            y: kLayoutSize.height * 0.1,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.8,
            surfaceId: 'primary'),
        SurfaceLayout(
            x: 0.0,
            y: kLayoutSize.height * 0.9,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.1,
            surfaceId: 'footer'),
      ])
    ];
    expect(compdel.getLayout(), equals(expectedLayout));
  });

  test('Primary, header, footer, aux either side', () {
    CompositionDelegate compdel = setupCompositionDelegate()
      ..addSurface(
        surface: Surface(
          surfaceId: 'primary',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'primary',
          },
        ),
      )
      ..focusSurface(surfaceId: 'primary')
      ..addSurface(
        surface: Surface(
          surfaceId: 'header',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'header',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'header')
      ..addSurface(
        surface: Surface(
          surfaceId: 'auxiliary_l',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'auxiliary',
            'hierarchy': 'parent',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'auxiliary_l')
      ..addSurface(
        surface: Surface(
          surfaceId: 'auxiliary_r',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'auxiliary',
            'hierarchy': 'child',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'auxiliary_r')
      ..addSurface(
        surface: Surface(
          surfaceId: 'footer',
          metadata: {
            'archetype': 'workspace',
            'archetype_role': 'footer',
          },
        ),
        parentId: 'primary',
      )
      ..focusSurface(surfaceId: 'footer');
    List<Layer> expectedLayout = <Layer>[
      Layer.fromList(elements: [
        SurfaceLayout(
            x: 0.0,
            y: 0.0,
            w: kLayoutSize.width,
            h: kLayoutSize.height * 0.1,
            surfaceId: 'header'),
        SurfaceLayout(
            x: 0.0,
            y: kLayoutSize.height * 0.1,
            w: kLayoutSize.width * 0.2,
            h: kLayoutSize.height * 0.9,
            surfaceId: 'auxiliary_l'),
        SurfaceLayout(
            x: kLayoutSize.width * 0.2,
            y: kLayoutSize.height * 0.1,
            w: kLayoutSize.width * 0.6,
            h: kLayoutSize.height * 0.8,
            surfaceId: 'primary'),
        SurfaceLayout(
            x: kLayoutSize.width * 0.2,
            y: kLayoutSize.height * 0.9,
            w: kLayoutSize.width * 0.6,
            h: kLayoutSize.height * 0.1,
            surfaceId: 'footer'),
        SurfaceLayout(
            x: kLayoutSize.width * 0.8,
            y: kLayoutSize.height * 0.1,
            w: kLayoutSize.width * 0.2,
            h: kLayoutSize.height * 0.9,
            surfaceId: 'auxiliary_r'),
      ])
    ];
    expect(compdel.getLayout(), equals(expectedLayout));
  });
}
