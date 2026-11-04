// Mock catalog for Rocket Market. Brands are fictional.
// Each text is a [arabic, english] pair.

export type L = [ar: string, en: string]

export interface RawCategory {
  id: number
  slug: string
  name: L
  emoji: string
  color: string
  subs: [slug: string, name: L][]
  brand: L
  description: L
}

export interface RawVariant {
  label: L
  price: number
  stock: number
  sale?: number
}

export interface RawProduct {
  id: number
  slug: string
  name: L
  cat: string
  sub: string
  emoji: string
  variants: RawVariant[]
  weight?: boolean
  tags: string[]
  brand?: L
}

export const CATEGORIES: RawCategory[] = [
  {
    id: 1, slug: 'fruits-vegetables', name: ['فواكه وخضروات', 'Fruits & Vegetables'], emoji: '🥬', color: '#E3F3DC',
    subs: [['fruits', ['فواكه', 'Fruits']], ['vegetables', ['خضروات', 'Vegetables']], ['herbs', ['أعشاب وورقيات', 'Herbs & Greens']]],
    brand: ['روكت فريش', 'Rocket Fresh'],
    description: ['يوصلك طازج من المزرعة كل يوم، متنقي بعناية ومتراجع قبل التغليف.', 'Farm-fresh every day, hand-picked and checked before packing.'],
  },
  {
    id: 2, slug: 'dairy-eggs', name: ['ألبان وبيض', 'Dairy & Eggs'], emoji: '🥛', color: '#E4EEFA',
    subs: [['milk', ['لبن', 'Milk']], ['cheese', ['جبن', 'Cheese']], ['yogurt', ['زبادي ولبنة', 'Yogurt & Labneh']], ['eggs', ['بيض وزبدة', 'Eggs & Butter']]],
    brand: ['ألبان الوادي', 'Valley Dairy'],
    description: ['منتج طازج محفوظ في التلاجة طول الطريق لحد باب البيت.', 'Kept chilled all the way to your door.'],
  },
  {
    id: 3, slug: 'bakery', name: ['مخبوزات', 'Bakery'], emoji: '🥐', color: '#FAEFD9',
    subs: [['bread', ['عيش', 'Bread']], ['pastries', ['معجنات وحلويات', 'Pastries & Sweets']]],
    brand: ['مخابز روكت', 'Rocket Bakery'],
    description: ['مخبوز طازة في مخابز روكت كل يوم الصبح.', 'Baked fresh every morning at Rocket Bakery.'],
  },
  {
    id: 4, slug: 'meat-poultry', name: ['لحوم ودواجن وأسماك', 'Meat, Poultry & Fish'], emoji: '🍗', color: '#FBE4E1',
    subs: [['beef', ['لحوم', 'Beef & Veal']], ['poultry', ['دواجن', 'Poultry']], ['seafood', ['أسماك وجمبري', 'Fish & Seafood']]],
    brand: ['جزارة روكت', 'Rocket Butchery'],
    description: ['قطعيات طازجة متجهزة بأعلى معايير الجودة، وبتتوزن وقت تجهيز طلبك.', 'Fresh cuts prepared to high standards and weighed when your order is packed.'],
  },
  {
    id: 5, slug: 'pantry', name: ['بقالة', 'Pantry'], emoji: '🍚', color: '#F4ECDA',
    subs: [['rice-pasta', ['أرز ومكرونة', 'Rice & Pasta']], ['oils', ['زيوت وسمن', 'Oils & Ghee']], ['canned', ['معلبات وبقوليات', 'Canned & Legumes']], ['essentials', ['سكر وملح وعسل', 'Sugar, Salt & Honey']]],
    brand: ['الذهبي', 'Golden'],
    description: ['من أساسيات كل بيت، بجودة مضمونة وسعر منافس.', 'A kitchen essential with guaranteed quality at a great price.'],
  },
  {
    id: 6, slug: 'beverages', name: ['مشروبات', 'Beverages'], emoji: '🧃', color: '#DFF2F5',
    subs: [['water', ['مياه', 'Water']], ['juices', ['عصائر', 'Juices']], ['soft-drinks', ['مياه غازية', 'Soft Drinks']], ['tea-coffee', ['شاي وقهوة', 'Tea & Coffee']]],
    brand: ['نقي', 'Naqi'],
    description: ['متوفر بأحجام مختلفة تناسب البيت كله.', 'Available in sizes for the whole family.'],
  },
  {
    id: 7, slug: 'snacks', name: ['سناكس وحلويات', 'Snacks & Sweets'], emoji: '🍫', color: '#F6E3EE',
    subs: [['chips', ['شيبسي وفشار', 'Chips & Popcorn']], ['chocolate', ['شوكولاتة وحلوى', 'Chocolate & Candy']], ['biscuits', ['بسكويت', 'Biscuits']], ['nuts', ['مكسرات وتمور', 'Nuts & Dates']]],
    brand: ['كرانشي', 'Crunchy'],
    description: ['السناك المثالي للخروجات والسهرات.', 'The perfect snack for outings and movie nights.'],
  },
  {
    id: 8, slug: 'household', name: ['منظفات ومستلزمات البيت', 'Household & Cleaning'], emoji: '🧴', color: '#E9E7F7',
    subs: [['laundry', ['غسيل', 'Laundry']], ['cleaning', ['تنظيف', 'Cleaning']], ['paper', ['مناديل وورقيات', 'Tissues & Paper']]],
    brand: ['لمعة', 'Lamaa'],
    description: ['نضافة ولمعة لبيتك بأفضل سعر.', 'Keep your home sparkling clean for less.'],
  },
]

const KG: L = ['للكيلو', 'per kg']
const v = (ar: string, en: string, price: number, stock: number, sale?: number): RawVariant => ({ label: [ar, en], price, stock, sale })
const kg = (price: number, stock: number, sale?: number): RawVariant => ({ label: KG, price, stock, sale })

export const PRODUCTS: RawProduct[] = [
  // Fruits & vegetables
  { id: 1, slug: 'banana', name: ['موز', 'Banana'], cat: 'fruits-vegetables', sub: 'fruits', emoji: '🍌', weight: true, variants: [kg(32, 80)], tags: ['best'] },
  { id: 2, slug: 'red-apple', name: ['تفاح أحمر', 'Red Apple'], cat: 'fruits-vegetables', sub: 'fruits', emoji: '🍎', weight: true, variants: [kg(85, 60, 75)], tags: [] },
  { id: 3, slug: 'baladi-orange', name: ['برتقال بلدي', 'Baladi Orange'], cat: 'fruits-vegetables', sub: 'fruits', emoji: '🍊', weight: true, variants: [kg(25, 90)], tags: [] },
  { id: 4, slug: 'strawberry', name: ['فراولة', 'Strawberry'], cat: 'fruits-vegetables', sub: 'fruits', emoji: '🍓', variants: [v('علبة 250 جم', '250 g box', 45, 30)], tags: ['new'] },
  { id: 5, slug: 'avocado', name: ['أفوكادو', 'Avocado'], cat: 'fruits-vegetables', sub: 'fruits', emoji: '🥑', variants: [v('قطعة', '1 piece', 35, 0)], tags: [] },
  { id: 6, slug: 'lemon', name: ['ليمون بلدي', 'Baladi Lemon'], cat: 'fruits-vegetables', sub: 'fruits', emoji: '🍋', weight: true, variants: [kg(40, 40)], tags: [] },
  { id: 7, slug: 'tomato', name: ['طماطم', 'Tomato'], cat: 'fruits-vegetables', sub: 'vegetables', emoji: '🍅', weight: true, variants: [kg(18, 200, 15)], tags: ['best'] },
  { id: 8, slug: 'potato', name: ['بطاطس', 'Potato'], cat: 'fruits-vegetables', sub: 'vegetables', emoji: '🥔', weight: true, variants: [kg(16, 200)], tags: ['best'] },
  { id: 9, slug: 'cucumber', name: ['خيار', 'Cucumber'], cat: 'fruits-vegetables', sub: 'vegetables', emoji: '🥒', weight: true, variants: [kg(20, 100)], tags: [] },
  { id: 10, slug: 'red-onion', name: ['بصل أحمر', 'Red Onion'], cat: 'fruits-vegetables', sub: 'vegetables', emoji: '🧅', weight: true, variants: [kg(14, 150)], tags: [] },
  { id: 11, slug: 'carrot', name: ['جزر', 'Carrot'], cat: 'fruits-vegetables', sub: 'vegetables', emoji: '🥕', weight: true, variants: [kg(15, 80)], tags: [] },
  { id: 12, slug: 'mint', name: ['نعناع', 'Fresh Mint'], cat: 'fruits-vegetables', sub: 'herbs', emoji: '🌿', variants: [v('حزمة', '1 bunch', 5, 50)], tags: [] },
  { id: 13, slug: 'parsley', name: ['بقدونس', 'Parsley'], cat: 'fruits-vegetables', sub: 'herbs', emoji: '🌱', variants: [v('حزمة', '1 bunch', 4, 50)], tags: [] },

  // Dairy & eggs
  { id: 14, slug: 'full-cream-milk', name: ['لبن كامل الدسم', 'Full Cream Milk'], cat: 'dairy-eggs', sub: 'milk', emoji: '🥛', variants: [v('1 لتر', '1 L', 38, 100), v('2 لتر', '2 L', 72, 60)], tags: ['best'] },
  { id: 15, slug: 'skimmed-milk', name: ['لبن خالي الدسم', 'Skimmed Milk'], cat: 'dairy-eggs', sub: 'milk', emoji: '🥛', variants: [v('1 لتر', '1 L', 40, 40)], tags: [] },
  { id: 16, slug: 'white-cheese', name: ['جبنة بيضاء', 'White Feta Cheese'], cat: 'dairy-eggs', sub: 'cheese', emoji: '🧀', variants: [v('500 جم', '500 g', 65, 50)], tags: [] },
  { id: 17, slug: 'cheddar-cheese', name: ['جبنة شيدر', 'Cheddar Cheese'], cat: 'dairy-eggs', sub: 'cheese', emoji: '🧀', variants: [v('200 جم', '200 g', 70, 30, 59)], tags: [] },
  { id: 18, slug: 'greek-yogurt', name: ['زبادي يوناني', 'Greek Yogurt'], cat: 'dairy-eggs', sub: 'yogurt', emoji: '🥣', variants: [v('170 جم', '170 g', 18, 60)], tags: [] },
  { id: 19, slug: 'plain-yogurt', name: ['زبادي طبيعي', 'Plain Yogurt'], cat: 'dairy-eggs', sub: 'yogurt', emoji: '🥣', variants: [v('105 جم', '105 g', 7.5, 120), v('6 × 105 جم', '6 × 105 g', 42, 40)], tags: ['best'] },
  { id: 20, slug: 'labneh', name: ['لبنة', 'Labneh'], cat: 'dairy-eggs', sub: 'yogurt', emoji: '🥣', variants: [v('250 جم', '250 g', 42, 25)], tags: ['new'] },
  { id: 21, slug: 'white-eggs', name: ['بيض أبيض', 'White Eggs'], cat: 'dairy-eggs', sub: 'eggs', emoji: '🥚', variants: [v('15 بيضة', '15 eggs', 85, 40), v('30 بيضة', '30 eggs', 165, 30, 155)], tags: ['best'] },
  { id: 22, slug: 'butter', name: ['زبدة', 'Butter'], cat: 'dairy-eggs', sub: 'eggs', emoji: '🧈', variants: [v('200 جم', '200 g', 95, 30)], tags: [] },

  // Bakery
  { id: 23, slug: 'baladi-bread', name: ['عيش بلدي', 'Baladi Bread'], cat: 'bakery', sub: 'bread', emoji: '🫓', variants: [v('5 أرغفة', '5 loaves', 10, 100)], tags: ['best'] },
  { id: 24, slug: 'toast-bread', name: ['عيش توست', 'Toast Bread'], cat: 'bakery', sub: 'bread', emoji: '🍞', variants: [v('600 جم', '600 g', 35, 40)], tags: [] },
  { id: 25, slug: 'baguette', name: ['باجيت فرنسي', 'French Baguette'], cat: 'bakery', sub: 'bread', emoji: '🥖', variants: [v('قطعة', '1 piece', 12, 30)], tags: [] },
  { id: 26, slug: 'butter-croissant', name: ['كرواسون بالزبدة', 'Butter Croissant'], cat: 'bakery', sub: 'pastries', emoji: '🥐', variants: [v('قطعة', '1 piece', 15, 40), v('4 قطع', '4 pieces', 55, 20)], tags: [] },
  { id: 27, slug: 'chocolate-muffin', name: ['مافن شوكولاتة', 'Chocolate Muffin'], cat: 'bakery', sub: 'pastries', emoji: '🧁', variants: [v('قطعة', '1 piece', 20, 25)], tags: [] },
  { id: 28, slug: 'vanilla-cake', name: ['كيكة فانيليا', 'Vanilla Cake'], cat: 'bakery', sub: 'pastries', emoji: '🍰', variants: [v('قطعة', '1 slice', 30, 15)], tags: ['new'] },

  // Meat, poultry & fish
  { id: 29, slug: 'whole-chicken', name: ['فراخ بيضاء كاملة', 'Whole Chicken'], cat: 'meat-poultry', sub: 'poultry', emoji: '🍗', weight: true, variants: [kg(115, 60)], tags: ['best'] },
  { id: 30, slug: 'chicken-breast', name: ['صدور فراخ', 'Chicken Breast'], cat: 'meat-poultry', sub: 'poultry', emoji: '🍗', weight: true, variants: [kg(190, 40)], tags: [] },
  { id: 31, slug: 'minced-beef', name: ['لحمة مفرومة', 'Minced Beef'], cat: 'meat-poultry', sub: 'beef', emoji: '🥩', weight: true, variants: [kg(420, 30, 399)], tags: [] },
  { id: 32, slug: 'veal-cubes', name: ['لحمة بتلو قطع', 'Veal Cubes'], cat: 'meat-poultry', sub: 'beef', emoji: '🍖', weight: true, variants: [kg(450, 25)], tags: [] },
  { id: 33, slug: 'beef-sausage', name: ['سجق بلدي', 'Beef Sausage'], cat: 'meat-poultry', sub: 'beef', emoji: '🌭', variants: [v('500 جم', '500 g', 140, 20)], tags: [] },
  { id: 34, slug: 'jumbo-shrimp', name: ['جمبري جامبو', 'Jumbo Shrimp'], cat: 'meat-poultry', sub: 'seafood', emoji: '🦐', weight: true, variants: [kg(550, 3)], tags: [] },
  { id: 35, slug: 'tilapia', name: ['سمك بلطي', 'Tilapia Fish'], cat: 'meat-poultry', sub: 'seafood', emoji: '🐟', weight: true, variants: [kg(95, 40)], tags: [] },

  // Pantry
  { id: 36, slug: 'egyptian-rice', name: ['أرز مصري', 'Egyptian Rice'], cat: 'pantry', sub: 'rice-pasta', emoji: '🍚', variants: [v('1 كجم', '1 kg', 38, 100), v('5 كجم', '5 kg', 180, 30, 169)], tags: ['best'] },
  { id: 37, slug: 'penne-pasta', name: ['مكرونة قلم', 'Penne Pasta'], cat: 'pantry', sub: 'rice-pasta', emoji: '🍝', variants: [v('400 جم', '400 g', 15, 150)], tags: [] },
  { id: 38, slug: 'sunflower-oil', name: ['زيت عباد الشمس', 'Sunflower Oil'], cat: 'pantry', sub: 'oils', emoji: '🌻', variants: [v('800 مل', '800 ml', 85, 60), v('2.2 لتر', '2.2 L', 220, 25)], tags: [] },
  { id: 39, slug: 'olive-oil', name: ['زيت زيتون بكر ممتاز', 'Extra Virgin Olive Oil'], cat: 'pantry', sub: 'oils', emoji: '🫒', variants: [v('500 مل', '500 ml', 210, 20)], tags: [] },
  { id: 40, slug: 'baladi-ghee', name: ['سمن بلدي', 'Baladi Ghee'], cat: 'pantry', sub: 'oils', emoji: '🫙', variants: [v('700 جم', '700 g', 230, 15)], tags: [] },
  { id: 41, slug: 'tuna-chunks', name: ['تونة قطع', 'Tuna Chunks'], cat: 'pantry', sub: 'canned', emoji: '🥫', variants: [v('160 جم', '160 g', 55, 60, 48)], tags: [] },
  { id: 42, slug: 'fava-beans', name: ['فول مدمس', 'Fava Beans'], cat: 'pantry', sub: 'canned', emoji: '🫘', variants: [v('400 جم', '400 g', 18, 80)], tags: ['best'] },
  { id: 43, slug: 'yellow-lentils', name: ['عدس أصفر', 'Yellow Lentils'], cat: 'pantry', sub: 'canned', emoji: '🫘', variants: [v('1 كجم', '1 kg', 60, 40)], tags: [] },
  { id: 44, slug: 'white-sugar', name: ['سكر أبيض', 'White Sugar'], cat: 'pantry', sub: 'essentials', emoji: '🍬', variants: [v('1 كجم', '1 kg', 32, 100)], tags: ['best'] },
  { id: 45, slug: 'table-salt', name: ['ملح طعام', 'Table Salt'], cat: 'pantry', sub: 'essentials', emoji: '🧂', variants: [v('700 جم', '700 g', 8, 60)], tags: [] },
  { id: 46, slug: 'bee-honey', name: ['عسل نحل', 'Bee Honey'], cat: 'pantry', sub: 'essentials', emoji: '🍯', variants: [v('450 جم', '450 g', 120, 20)], tags: [] },

  // Beverages
  { id: 47, slug: 'mineral-water', name: ['مياه معدنية', 'Mineral Water'], cat: 'beverages', sub: 'water', emoji: '💧', variants: [v('600 مل', '600 ml', 6, 200), v('1.5 لتر', '1.5 L', 9, 200), v('6 × 1.5 لتر', '6 × 1.5 L', 50, 50)], tags: ['best'] },
  { id: 48, slug: 'orange-juice', name: ['عصير برتقال طبيعي', 'Fresh Orange Juice'], cat: 'beverages', sub: 'juices', emoji: '🧃', variants: [v('1 لتر', '1 L', 45, 40)], tags: [] },
  { id: 49, slug: 'mango-juice', name: ['عصير مانجو', 'Mango Juice'], cat: 'beverages', sub: 'juices', emoji: '🥭', variants: [v('1 لتر', '1 L', 48, 40, 40)], tags: [] },
  { id: 50, slug: 'cola', name: ['مشروب كولا', 'Cola'], cat: 'beverages', sub: 'soft-drinks', emoji: '🥤', variants: [v('1 لتر', '1 L', 25, 80), v('6 × 330 مل', '6 × 330 ml', 75, 30)], tags: [] },
  { id: 51, slug: 'black-tea', name: ['شاي أسود', 'Black Tea'], cat: 'beverages', sub: 'tea-coffee', emoji: '🍵', variants: [v('40 كيس', '40 bags', 60, 50), v('250 جم', '250 g', 75, 40)], tags: [] },
  { id: 52, slug: 'turkish-coffee', name: ['بن تركي محوج', 'Turkish Coffee with Cardamom'], cat: 'beverages', sub: 'tea-coffee', emoji: '☕', variants: [v('200 جم', '200 g', 160, 25)], tags: ['new'] },

  // Snacks & sweets
  { id: 53, slug: 'potato-chips', name: ['شيبسي بطاطس بالملح', 'Salted Potato Chips'], cat: 'snacks', sub: 'chips', emoji: '🍟', variants: [v('كيس كبير', 'Large bag', 15, 100)], tags: ['best'] },
  { id: 54, slug: 'butter-popcorn', name: ['فشار بالزبدة', 'Butter Popcorn'], cat: 'snacks', sub: 'chips', emoji: '🍿', variants: [v('100 جم', '100 g', 20, 40)], tags: ['new'] },
  { id: 55, slug: 'milk-chocolate', name: ['شوكولاتة باللبن', 'Milk Chocolate'], cat: 'snacks', sub: 'chocolate', emoji: '🍫', variants: [v('100 جم', '100 g', 45, 60, 39)], tags: [] },
  { id: 56, slug: 'jelly-candy', name: ['حلوى جيلي', 'Jelly Candy'], cat: 'snacks', sub: 'chocolate', emoji: '🍬', variants: [v('150 جم', '150 g', 25, 40)], tags: [] },
  { id: 57, slug: 'tea-biscuits', name: ['بسكويت شاي', 'Tea Biscuits'], cat: 'snacks', sub: 'biscuits', emoji: '🍪', variants: [v('عبوة', '1 pack', 12, 100), v('12 عبوة', '12 packs', 130, 20)], tags: [] },
  { id: 58, slug: 'mixed-nuts', name: ['مكسرات مشكلة', 'Mixed Nuts'], cat: 'snacks', sub: 'nuts', emoji: '🥜', variants: [v('250 جم', '250 g', 140, 25)], tags: [] },
  { id: 59, slug: 'siwa-dates', name: ['تمر سيوي', 'Siwa Dates'], cat: 'snacks', sub: 'nuts', emoji: '🌴', variants: [v('500 جم', '500 g', 60, 40)], tags: [] },

  // Household
  { id: 60, slug: 'laundry-powder', name: ['مسحوق غسيل أوتوماتيك', 'Automatic Laundry Powder'], cat: 'household', sub: 'laundry', emoji: '🧺', variants: [v('2.5 كجم', '2.5 kg', 210, 30), v('4 كجم', '4 kg', 320, 20, 295)], tags: [] },
  { id: 61, slug: 'fabric-softener', name: ['منعم أقمشة', 'Fabric Softener'], cat: 'household', sub: 'laundry', emoji: '🌸', variants: [v('1 لتر', '1 L', 70, 30)], tags: ['new'] },
  { id: 62, slug: 'dish-soap', name: ['سائل غسيل أطباق', 'Dish Soap'], cat: 'household', sub: 'cleaning', emoji: '🧽', variants: [v('1 لتر', '1 L', 45, 50, 39)], tags: [] },
  { id: 63, slug: 'floor-cleaner', name: ['منظف أرضيات', 'Floor Cleaner'], cat: 'household', sub: 'cleaning', emoji: '🧴', variants: [v('3 لتر', '3 L', 95, 25)], tags: [] },
  { id: 64, slug: 'trash-bags', name: ['أكياس قمامة', 'Trash Bags'], cat: 'household', sub: 'cleaning', emoji: '🗑️', variants: [v('30 كيس', '30 bags', 35, 40)], tags: [] },
  { id: 65, slug: 'facial-tissues', name: ['مناديل وجه', 'Facial Tissues'], cat: 'household', sub: 'paper', emoji: '🧻', variants: [v('5 علب', '5 boxes', 85, 30)], tags: [] },
  { id: 66, slug: 'toilet-paper', name: ['ورق تواليت', 'Toilet Paper'], cat: 'household', sub: 'paper', emoji: '🧻', variants: [v('9 لفات', '9 rolls', 110, 30)], tags: ['best'] },
]

export const BANNERS = [
  {
    id: 1, tone: 'green' as const, emoji: '🥑🍓', link: '/category/fruits-vegetables',
    title: ['خضار وفاكهة طازة كل يوم', 'Fresh produce, every day'] as L,
    subtitle: ['من المزرعة لباب البيت في نفس اليوم', 'From the farm to your door, same day'] as L,
    cta: ['تسوق دلوقتي', 'Shop now'] as L,
  },
  {
    id: 2, tone: 'orange' as const, emoji: '🎁', link: '/search?tag=offer',
    title: ['خصم 10% على طلبك', '10% off your order'] as L,
    subtitle: ['استخدم كود ROCKET10 للطلبات فوق 200 ج.م', 'Use code ROCKET10 on orders over EGP 200'] as L,
    cta: ['شوف العروض', 'See offers'] as L,
  },
  {
    id: 3, tone: 'blue' as const, emoji: '🚀', link: '/categories',
    title: ['توصيل مجاني فوق 500 ج.م', 'Free delivery over EGP 500'] as L,
    subtitle: ['أو استلم طلبك من روكت مول ببلاش', 'Or pick up from Rocket Mall for free'] as L,
    cta: ['ابدأ التسوق', 'Start shopping'] as L,
  },
]

export const ZONES: { id: string; name: L; fee: number }[] = [
  { id: 'cairo', name: ['القاهرة', 'Cairo'], fee: 25 },
  { id: 'giza', name: ['الجيزة', 'Giza'], fee: 30 },
  { id: 'qalyubia', name: ['القليوبية', 'Qalyubia'], fee: 40 },
  { id: 'alexandria', name: ['الإسكندرية', 'Alexandria'], fee: 60 },
]

export const STORE_RULES = {
  freeDeliveryThreshold: 500,
  minOrder: 100,
  codLimit: 3000,
  defaultZone: 'cairo',
  pickup: {
    name: ['روكت مول، الدور الأرضي', 'Rocket Mall, ground floor'] as L,
    address: ['استلم طلبك من مكتب الاستلام جنب البوابة الرئيسية', 'Collect your order at the pickup desk by the main gate'] as L,
    hours: ['يوميًا من 9 الصبح لـ 11 بالليل', 'Daily, 9 AM to 11 PM'] as L,
  },
}

export const COUPONS: Record<string, { type: 'percent' | 'fixed' | 'free_delivery'; value: number; min: number; max?: number }> = {
  ROCKET10: { type: 'percent', value: 10, min: 200, max: 100 },
  SAVE50: { type: 'fixed', value: 50, min: 400 },
  FREESHIP: { type: 'free_delivery', value: 0, min: 150 },
}
