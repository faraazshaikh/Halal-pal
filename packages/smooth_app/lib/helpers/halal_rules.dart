/// Personal halal rules for the halal check card.
///
/// Edit these lists to change verdicts. Keywords are matched as whole words
/// (case-insensitive) against the ingredient text. E-numbers are matched
/// against the ingredient text and the additive names of the product.
///
/// These rules are a starting point built on the general-consensus view that
/// pork derivatives, alcohol, carmine and unspecified gelatin are not halal,
/// and that several emulsifiers/enzymes depend on their source. Review them
/// before relying on them.
library;

/// A rule: [term] is a keyword or an E-number (e.g. "E120").
class HalalRule {
  const HalalRule(this.term, this.reason);

  final String term;
  final String reason;
}

/// Always flagged as haram.
const List<HalalRule> HALAL_HARAM_KEYWORDS = <HalalRule>[
  HalalRule('pork', 'Pork'),
  HalalRule('pig', 'Pork'),
  HalalRule('swine', 'Pork'),
  HalalRule('lard', 'Pork fat'),
  HalalRule('bacon', 'Pork'),
  HalalRule('ham', 'Pork'),
  HalalRule('prosciutto', 'Pork'),
  HalalRule('pancetta', 'Pork'),
  HalalRule('salami', 'Usually pork'),
  HalalRule('alcohol', 'Alcohol'),
  HalalRule('wine', 'Alcohol'),
  HalalRule('beer', 'Alcohol'),
  HalalRule('rum', 'Alcohol'),
  HalalRule('brandy', 'Alcohol'),
  HalalRule('whisky', 'Alcohol'),
  HalalRule('whiskey', 'Alcohol'),
  HalalRule('vodka', 'Alcohol'),
  HalalRule('liqueur', 'Alcohol'),
  HalalRule('sake', 'Alcohol'),
  HalalRule('cochineal', 'Insect-derived dye (carmine)'),
  HalalRule('carmine', 'Insect-derived dye (carmine)'),
  HalalRule('carminic acid', 'Insect-derived dye (carmine)'),
];

/// E-numbers always flagged as haram.
const List<HalalRule> HALAL_HARAM_E_NUMBERS = <HalalRule>[
  HalalRule('E120', 'Carmine / cochineal (insect-derived)'),
  HalalRule('E542', 'Edible bone phosphate (animal bones)'),
];

/// Gelatin is haram unless the text says what animal it comes from.
const List<String> HALAL_GELATIN_TERMS = <String>['gelatin', 'gelatine'];
const String HALAL_GELATIN_E_NUMBER = 'E441';

/// Words near "gelatin" that mean the source is stated (then: doubtful, not
/// haram, because the source still needs verifying).
const List<String> HALAL_GELATIN_SOURCE_WORDS = <String>[
  'fish',
  'bovine',
  'beef',
  'halal',
  'plant',
  'vegetable',
  'vegan',
];

/// Flagged as doubtful (mushbooh): the verdict depends on the source.
const List<HalalRule> HALAL_MUSHBOOH_KEYWORDS = <HalalRule>[
  HalalRule('rennet', 'Animal rennet may come from non-zabiha animals'),
  HalalRule('pepsin', 'Often pork-derived enzyme'),
  HalalRule('lipase', 'Animal or microbial enzyme'),
  HalalRule('l-cysteine', 'Can come from hair or feathers'),
  HalalRule('cysteine', 'Can come from hair or feathers'),
  HalalRule('shellac', 'Insect secretion; scholars differ'),
  HalalRule('glycerin', 'Animal, plant or synthetic source'),
  HalalRule('glycerine', 'Animal, plant or synthetic source'),
  HalalRule('glycerol', 'Animal, plant or synthetic source'),
  HalalRule(
    'mono- and diglycerides',
    'Emulsifier: animal or plant source',
  ),
  HalalRule(
    'mono and diglycerides',
    'Emulsifier: animal or plant source',
  ),
  HalalRule('monoglycerides', 'Emulsifier: animal or plant source'),
  HalalRule('diglycerides', 'Emulsifier: animal or plant source'),
  HalalRule('vanilla extract', 'Usually made with alcohol'),
  HalalRule('natural flavour', 'May use alcohol or animal carriers'),
  HalalRule('natural flavor', 'May use alcohol or animal carriers'),
  HalalRule('natural flavours', 'May use alcohol or animal carriers'),
  HalalRule('natural flavors', 'May use alcohol or animal carriers'),
  HalalRule('ethanol', 'Alcohol used as a carrier or solvent'),
  HalalRule('whey', 'Can be made with animal rennet'),
  HalalRule('lecithin', 'Usually soy, can be egg or animal'),
  HalalRule('tallow', 'Animal fat: source animal unknown'),
];

/// E-numbers flagged as doubtful (mushbooh).
const List<HalalRule> HALAL_MUSHBOOH_E_NUMBERS = <HalalRule>[
  HalalRule('E422', 'Glycerol: animal or plant source'),
  HalalRule('E430', 'Polyoxyethylene stearate: source unclear'),
  HalalRule('E431', 'Polyoxyethylene stearate: source unclear'),
  HalalRule('E432', 'Polysorbate: fatty acid source unclear'),
  HalalRule('E433', 'Polysorbate: fatty acid source unclear'),
  HalalRule('E434', 'Polysorbate: fatty acid source unclear'),
  HalalRule('E435', 'Polysorbate: fatty acid source unclear'),
  HalalRule('E436', 'Polysorbate: fatty acid source unclear'),
  HalalRule('E470', 'Fatty acid salts: animal or plant source'),
  HalalRule('E470A', 'Fatty acid salts: animal or plant source'),
  HalalRule('E470B', 'Fatty acid salts: animal or plant source'),
  HalalRule('E471', 'Mono/diglycerides: animal or plant source'),
  HalalRule('E472A', 'Emulsifier: animal or plant source'),
  HalalRule('E472B', 'Emulsifier: animal or plant source'),
  HalalRule('E472C', 'Emulsifier: animal or plant source'),
  HalalRule('E472D', 'Emulsifier: animal or plant source'),
  HalalRule('E472E', 'Emulsifier: animal or plant source'),
  HalalRule('E472F', 'Emulsifier: animal or plant source'),
  HalalRule('E473', 'Sucrose esters: fatty acid source unclear'),
  HalalRule('E474', 'Sucroglycerides: fatty acid source unclear'),
  HalalRule('E475', 'Polyglycerol esters: fatty acid source unclear'),
  HalalRule('E476', 'Polyglycerol polyricinoleate: source unclear'),
  HalalRule('E477', 'Propylene glycol esters: source unclear'),
  HalalRule('E479B', 'Emulsifier: source unclear'),
  HalalRule('E481', 'Stearoyl lactylate: source unclear'),
  HalalRule('E482', 'Calcium lactylate: source unclear'),
  HalalRule('E483', 'Stearyl tartrate: source unclear'),
  HalalRule('E491', 'Sorbitan ester: source unclear'),
  HalalRule('E492', 'Sorbitan ester: source unclear'),
  HalalRule('E493', 'Sorbitan ester: source unclear'),
  HalalRule('E494', 'Sorbitan ester: source unclear'),
  HalalRule('E495', 'Sorbitan ester: source unclear'),
  HalalRule('E570', 'Stearic acid: animal or plant source'),
  HalalRule('E572', 'Magnesium stearate: animal or plant source'),
  HalalRule('E627', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E631', 'Disodium inosinate: often animal-derived'),
  HalalRule('E635', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E904', 'Shellac: insect secretion; scholars differ'),
  HalalRule('E913', 'Lanolin: from sheep wool'),
  HalalRule('E920', 'L-cysteine: can come from hair or feathers'),
  HalalRule('E921', 'Cystine: can come from hair or feathers'),
  HalalRule('E1105', 'Lysozyme: from egg white'),
];
