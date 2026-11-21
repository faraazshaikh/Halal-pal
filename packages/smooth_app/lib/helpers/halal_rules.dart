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
  HalalRule('ethyl alcohol', 'Alcohol'),
  HalalRule('cognac', 'Alcohol'),
  HalalRule('champagne', 'Alcohol'),
  HalalRule('bourbon', 'Alcohol'),
  HalalRule('tequila', 'Alcohol'),
  HalalRule('sherry', 'Alcohol'),
  HalalRule('mirin', 'Contains alcohol'),
  HalalRule('cooking wine', 'Alcohol'),
  HalalRule('rum extract', 'Alcohol'),
  HalalRule('gammon', 'Pork'),
  HalalRule('lardons', 'Pork'),
  HalalRule('chorizo', 'Usually pork'),
  HalalRule('pepperoni', 'Usually pork'),
  HalalRule('suar', 'Pork (Hindi/Urdu)'),
  HalalRule('sharab', 'Alcohol (Hindi/Urdu)'),
  HalalRule('khinzir', 'Pork (Arabic)'),
  HalalRule('porcine', 'Pork'),
  HalalRule('hog', 'Pork'),
  HalalRule('blood', 'Blood'),
  HalalRule('haemoglobin', 'Blood'),
  HalalRule('hemoglobin', 'Blood'),
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
  HalalRule('suet', 'Animal fat: source animal unknown'),
  HalalRule('animal fat', 'Animal fat: source animal unknown'),
  HalalRule('animal shortening', 'Animal fat: source animal unknown'),
  HalalRule('collagen', 'Animal-derived: source animal unknown'),
  HalalRule('natural flavouring', 'May use alcohol or animal carriers'),
  HalalRule('natural flavoring', 'May use alcohol or animal carriers'),
  HalalRule('vanilla essence', 'May be made with alcohol'),
  HalalRule('bone', 'Animal bones: source animal unknown'),
  // Flavourings: the source and any alcohol carrier are not on the label.
  HalalRule('flavouring', HALAL_FLAVOURING_REASON),
  HalalRule('flavourings', HALAL_FLAVOURING_REASON),
  HalalRule('flavoring', HALAL_FLAVOURING_REASON),
  HalalRule('flavorings', HALAL_FLAVOURING_REASON),
  HalalRule('flavour', HALAL_FLAVOURING_REASON),
  HalalRule('flavor', HALAL_FLAVOURING_REASON),
  HalalRule('aroma', HALAL_FLAVOURING_REASON),
  HalalRule('aromas', HALAL_FLAVOURING_REASON),
  // Meat: halal only if slaughtered the halal way, which a label rarely says.
  HalalRule('chicken', _MEAT_REASON),
  HalalRule('beef', _MEAT_REASON),
  HalalRule('lamb', _MEAT_REASON),
  HalalRule('mutton', _MEAT_REASON),
  HalalRule('turkey', _MEAT_REASON),
  HalalRule('duck', _MEAT_REASON),
  HalalRule('veal', _MEAT_REASON),
  HalalRule('goat', _MEAT_REASON),
  HalalRule('venison', _MEAT_REASON),
  HalalRule('poultry', _MEAT_REASON),
  HalalRule('meat', _MEAT_REASON),
  HalalRule('castoreum', 'Beaver gland secretion'),
  HalalRule('confectioner\'s glaze', 'Shellac: insect secretion; scholars differ'),
  HalalRule('confectioners glaze', 'Shellac: insect secretion; scholars differ'),
  HalalRule('stearic acid', 'Animal or plant source'),
  HalalRule('magnesium stearate', 'Animal or plant source'),
];

/// Reason text of the plain flavouring rules (also used to spot them).
const String HALAL_FLAVOURING_REASON =
    'Flavouring: source and any alcohol carrier not stated';
const String _MEAT_REASON =
    'Meat: halal only if slaughtered the halal way (no halal label found)';

/// Source words that, when written next to a doubtful ingredient, say it is
/// fine after all (for example "microbial rennet" or "soya lecithin"), so it
/// is not flagged. The text window checked is a few words either side.
const List<String> _NOT_ALCOHOL_OR_HALAL = <String>[
  'halal',
  'alcohol free',
  'alcohol-free',
  'non-alcoholic',
];
const List<String> _MEAT_HALAL_WORDS = <String>[
  'halal',
  'zabiha',
  'zabihah',
  'dhabiha',
  'dhabihah',
];
const List<String> _PLANT_WORDS = <String>[
  'vegetable',
  'plant',
  'palm',
  'coconut',
];

const Map<String, List<String>> HALAL_SOURCE_EXEMPTIONS =
    <String, List<String>>{
      'rennet': <String>[
        'microbial',
        'vegetable',
        'vegetarian',
        'non-animal',
        'non animal',
        'fermentation',
        'plant',
      ],
      'lipase': <String>['microbial', 'fungal', 'vegetable', 'plant'],
      'lecithin': <String>['soy', 'soya', 'sunflower', 'rapeseed', 'canola'],
      'glycerin': _PLANT_WORDS,
      'glycerine': _PLANT_WORDS,
      'glycerol': _PLANT_WORDS,
      'suet': _PLANT_WORDS,
      'tallow': _PLANT_WORDS,
      'collagen': <String>['fish', 'marine', 'plant', 'halal'],
      'flavouring': _NOT_ALCOHOL_OR_HALAL,
      'flavourings': _NOT_ALCOHOL_OR_HALAL,
      'flavoring': _NOT_ALCOHOL_OR_HALAL,
      'flavorings': _NOT_ALCOHOL_OR_HALAL,
      'flavour': _NOT_ALCOHOL_OR_HALAL,
      'flavor': _NOT_ALCOHOL_OR_HALAL,
      'aroma': _NOT_ALCOHOL_OR_HALAL,
      'aromas': _NOT_ALCOHOL_OR_HALAL,
      'natural flavour': _NOT_ALCOHOL_OR_HALAL,
      'natural flavor': _NOT_ALCOHOL_OR_HALAL,
      'natural flavours': _NOT_ALCOHOL_OR_HALAL,
      'natural flavors': _NOT_ALCOHOL_OR_HALAL,
      'natural flavouring': _NOT_ALCOHOL_OR_HALAL,
      'natural flavoring': _NOT_ALCOHOL_OR_HALAL,
      'chicken': _MEAT_HALAL_WORDS,
      'beef': _MEAT_HALAL_WORDS,
      'lamb': _MEAT_HALAL_WORDS,
      'mutton': _MEAT_HALAL_WORDS,
      'turkey': _MEAT_HALAL_WORDS,
      'duck': _MEAT_HALAL_WORDS,
      'veal': _MEAT_HALAL_WORDS,
      'goat': _MEAT_HALAL_WORDS,
      'venison': _MEAT_HALAL_WORDS,
      'poultry': _MEAT_HALAL_WORDS,
      'meat': _MEAT_HALAL_WORDS,
    };

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
  HalalRule('E153', 'Vegetable carbon: can be made from animal bones'),
  HalalRule('E334', 'Tartaric acid: often a by-product of wine'),
  HalalRule('E335', 'Tartrate: often a by-product of wine'),
  HalalRule('E336', 'Tartrate: often a by-product of wine'),
  HalalRule('E337', 'Tartrate: often a by-product of wine'),
  HalalRule('E353', 'Metatartaric acid: often from wine'),
  HalalRule('E626', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E628', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E629', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E630', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E632', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E633', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E634', 'Flavour enhancer: may be animal-derived'),
  HalalRule('E640', 'Glycine: can be animal-derived'),
  HalalRule('E1000', 'Cholic acid: from animal bile'),
  HalalRule('E1518', 'Triacetin: made from glycerol of unclear source'),
];
