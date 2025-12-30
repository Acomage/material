module
public import Material.DynamicColor.DSL

def darkLightConst1 : ToneFnsExpr 1 :=
  .darkLight (.const 6) (.const 98)


def primaryPaletteKeyColor : ToneFnsExpr 1 :=
  .palette .primary

def secondaryPaletteKeyColor : ToneFnsExpr 1 :=
  .palette .secondary

def tertiaryPaletteKeyColor : ToneFnsExpr 1 :=
  .palette .tertiary

def neutralPaletteKeyColor : ToneFnsExpr 1 :=
  .palette .neutral

def neutralVariantPaletteKeyColor : ToneFnsExpr 1 :=
  .palette .neutralVariant

def background : ToneFnsExpr 1 := darkLightConst1

