import '../../../shared/domain/life_item_type.dart';
import '../../../shared/domain/recurrence.dart';

/// A thing most people pay for, ready to be added without a document.
///
/// This exists because of the first two minutes. A new account has nothing in
/// it, and an app whose question is "what do I have coming up" has nothing to
/// answer with until a receipt happens to arrive. Picking "Netflix, 13,49 €,
/// the 4th" from a list takes ten seconds and makes the app worth opening
/// before the first capture ever happens.
class KnownService {
  const KnownService({
    required this.name,
    required this.type,
    required this.frequency,
    this.currency,
  });

  /// A proper noun. Deliberately not translated: Netflix is Netflix in every
  /// locale, and a translated brand looks like a different company.
  final String name;

  final LifeItemType type;

  /// How it usually renews. The user can change it before saving; this is only
  /// what the form opens with.
  final RecurrenceFrequency frequency;

  /// Left null when it genuinely varies by country.
  final String? currency;
}

/// The ones with no brand behind them: rent, the gym, the car inspection.
///
/// Separate from [KnownService] because these do need translating, and a
/// name that comes from the interface language cannot live in a const list.
enum GenericService {
  rent(LifeItemType.home, RecurrenceFrequency.monthly),
  condominium(LifeItemType.home, RecurrenceFrequency.monthly),
  councilTax(LifeItemType.home, RecurrenceFrequency.yearly),
  electricity(LifeItemType.bill, RecurrenceFrequency.monthly),
  water(LifeItemType.bill, RecurrenceFrequency.monthly),
  gas(LifeItemType.bill, RecurrenceFrequency.monthly),
  internet(LifeItemType.bill, RecurrenceFrequency.monthly),
  mobile(LifeItemType.bill, RecurrenceFrequency.monthly),
  gym(LifeItemType.subscription, RecurrenceFrequency.monthly),
  carInsurance(LifeItemType.insurance, RecurrenceFrequency.yearly),
  homeInsurance(LifeItemType.insurance, RecurrenceFrequency.yearly),
  healthInsurance(LifeItemType.insurance, RecurrenceFrequency.yearly),
  lifeInsurance(LifeItemType.insurance, RecurrenceFrequency.yearly),
  carInspection(LifeItemType.vehicle, RecurrenceFrequency.yearly),
  roadTax(LifeItemType.vehicle, RecurrenceFrequency.yearly),
  passport(LifeItemType.document, RecurrenceFrequency.yearly),
  idCard(LifeItemType.document, RecurrenceFrequency.yearly),
  driversLicence(LifeItemType.document, RecurrenceFrequency.yearly),
  dentist(LifeItemType.appointment, RecurrenceFrequency.yearly),
  medicalCheckup(LifeItemType.appointment, RecurrenceFrequency.yearly);

  const GenericService(this.type, this.frequency);

  final LifeItemType type;
  final RecurrenceFrequency frequency;
}

const _sub = LifeItemType.subscription;
const _monthly = RecurrenceFrequency.monthly;
const _yearly = RecurrenceFrequency.yearly;

/// Weighted towards Portugal, Spain and Brazil, because those are the locales
/// the app ships in. Global services first, then the ones that only mean
/// something in one market.
const List<KnownService> knownServices = [
  // Video
  KnownService(name: 'Netflix', type: _sub, frequency: _monthly),
  KnownService(name: 'Disney+', type: _sub, frequency: _monthly),
  KnownService(name: 'HBO Max', type: _sub, frequency: _monthly),
  KnownService(name: 'Amazon Prime', type: _sub, frequency: _monthly),
  KnownService(name: 'Apple TV+', type: _sub, frequency: _monthly),
  KnownService(name: 'SkyShowtime', type: _sub, frequency: _monthly),
  KnownService(name: 'Filmin', type: _sub, frequency: _monthly),
  KnownService(name: 'Globoplay', type: _sub, frequency: _monthly),
  KnownService(name: 'DAZN', type: _sub, frequency: _monthly),
  KnownService(name: 'Twitch', type: _sub, frequency: _monthly),

  // Music, audio and books
  KnownService(name: 'Spotify', type: _sub, frequency: _monthly),
  KnownService(name: 'Apple Music', type: _sub, frequency: _monthly),
  KnownService(name: 'YouTube Premium', type: _sub, frequency: _monthly),
  KnownService(name: 'Deezer', type: _sub, frequency: _monthly),
  KnownService(name: 'Tidal', type: _sub, frequency: _monthly),
  KnownService(name: 'SoundCloud Go', type: _sub, frequency: _monthly),
  KnownService(name: 'Audible', type: _sub, frequency: _monthly),
  KnownService(name: 'Kindle Unlimited', type: _sub, frequency: _monthly),
  KnownService(name: 'Storytel', type: _sub, frequency: _monthly),

  // Storage and productivity
  KnownService(name: 'iCloud+', type: _sub, frequency: _monthly),
  KnownService(name: 'Google One', type: _sub, frequency: _monthly),
  KnownService(name: 'Dropbox', type: _sub, frequency: _monthly),
  KnownService(name: 'OneDrive', type: _sub, frequency: _monthly),
  KnownService(name: 'Microsoft 365', type: _sub, frequency: _yearly),
  KnownService(name: 'Adobe Creative Cloud', type: _sub, frequency: _monthly),
  KnownService(name: 'Canva', type: _sub, frequency: _monthly),
  KnownService(name: 'Figma', type: _sub, frequency: _monthly),
  KnownService(name: 'Notion', type: _sub, frequency: _monthly),
  KnownService(name: 'Slack', type: _sub, frequency: _monthly),
  KnownService(name: 'Zoom', type: _sub, frequency: _monthly),
  KnownService(name: 'Todoist', type: _sub, frequency: _yearly),
  KnownService(name: 'Evernote', type: _sub, frequency: _monthly),
  KnownService(name: '1Password', type: _sub, frequency: _yearly),
  KnownService(name: 'LastPass', type: _sub, frequency: _yearly),

  // AI and developer tools
  KnownService(name: 'ChatGPT Plus', type: _sub, frequency: _monthly),
  KnownService(name: 'Claude Pro', type: _sub, frequency: _monthly),
  KnownService(name: 'Google Gemini', type: _sub, frequency: _monthly),
  KnownService(name: 'GitHub', type: _sub, frequency: _monthly),
  KnownService(name: 'GitHub Copilot', type: _sub, frequency: _monthly),
  KnownService(name: 'JetBrains', type: _sub, frequency: _yearly),
  KnownService(name: 'Vercel', type: _sub, frequency: _monthly),
  KnownService(name: 'Supabase', type: _sub, frequency: _monthly),
  KnownService(name: 'Cloudflare', type: _sub, frequency: _monthly),

  // VPN and security
  KnownService(name: 'NordVPN', type: _sub, frequency: _yearly),
  KnownService(name: 'Surfshark', type: _sub, frequency: _yearly),
  KnownService(name: 'ExpressVPN', type: _sub, frequency: _yearly),
  KnownService(name: 'Proton', type: _sub, frequency: _yearly),

  // Gaming
  KnownService(name: 'Xbox Game Pass', type: _sub, frequency: _monthly),
  KnownService(name: 'PlayStation Plus', type: _sub, frequency: _yearly),
  KnownService(name: 'Nintendo Switch Online', type: _sub, frequency: _yearly),
  KnownService(name: 'EA Play', type: _sub, frequency: _monthly),

  // Health, sport and learning
  KnownService(name: 'Strava', type: _sub, frequency: _yearly),
  KnownService(name: 'Fitbit Premium', type: _sub, frequency: _monthly),
  KnownService(name: 'Whoop', type: _sub, frequency: _monthly),
  KnownService(name: 'MyFitnessPal', type: _sub, frequency: _monthly),
  KnownService(name: 'Headspace', type: _sub, frequency: _yearly),
  KnownService(name: 'Calm', type: _sub, frequency: _yearly),
  KnownService(name: 'Duolingo', type: _sub, frequency: _yearly),
  KnownService(name: 'Babbel', type: _sub, frequency: _yearly),
  KnownService(name: 'Coursera', type: _sub, frequency: _monthly),
  KnownService(name: 'Udemy', type: _sub, frequency: _monthly),
  KnownService(name: 'Fitness Hut', type: _sub, frequency: _monthly),
  KnownService(name: 'Holmes Place', type: _sub, frequency: _monthly),
  KnownService(name: 'Solinca', type: _sub, frequency: _monthly),
  KnownService(name: 'Smart Fit', type: _sub, frequency: _monthly),
  KnownService(name: 'Basic-Fit', type: _sub, frequency: _monthly),

  // Delivery and mobility
  KnownService(name: 'Uber One', type: _sub, frequency: _monthly),
  KnownService(name: 'Bolt', type: _sub, frequency: _monthly),
  KnownService(name: 'Glovo Prime', type: _sub, frequency: _monthly),
  KnownService(name: 'Uber Eats', type: _sub, frequency: _monthly),
  KnownService(name: 'iFood', type: _sub, frequency: _monthly),
  KnownService(
    name: 'Via Verde',
    type: LifeItemType.vehicle,
    frequency: _monthly,
  ),

  // Telecoms - Portugal
  KnownService(name: 'MEO', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'NOS', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Vodafone', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'NOWO', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Digi', type: LifeItemType.bill, frequency: _monthly),
  // Telecoms - Spain and Brazil
  KnownService(name: 'Movistar', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Orange', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Yoigo', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Claro', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Vivo', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'TIM', type: LifeItemType.bill, frequency: _monthly),

  // Energy and water
  KnownService(name: 'EDP', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Galp', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Endesa', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Iberdrola', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Repsol', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Naturgy', type: LifeItemType.bill, frequency: _monthly),
  KnownService(name: 'Enel', type: LifeItemType.bill, frequency: _monthly),

  // Insurance and health plans
  KnownService(
    name: 'Fidelidade',
    type: LifeItemType.insurance,
    frequency: _yearly,
  ),
  KnownService(name: 'Ageas', type: LifeItemType.insurance, frequency: _yearly),
  KnownService(
    name: 'Allianz',
    type: LifeItemType.insurance,
    frequency: _yearly,
  ),
  KnownService(
    name: 'Zurich',
    type: LifeItemType.insurance,
    frequency: _yearly,
  ),
  KnownService(
    name: 'Mapfre',
    type: LifeItemType.insurance,
    frequency: _yearly,
  ),
  KnownService(name: 'AXA', type: LifeItemType.insurance, frequency: _yearly),
  KnownService(
    name: 'Generali',
    type: LifeItemType.insurance,
    frequency: _yearly,
  ),
  KnownService(
    name: 'Médis',
    type: LifeItemType.insurance,
    frequency: _monthly,
  ),
  KnownService(
    name: 'Multicare',
    type: LifeItemType.insurance,
    frequency: _monthly,
  ),
  KnownService(
    name: 'SulAmérica',
    type: LifeItemType.insurance,
    frequency: _monthly,
  ),
  KnownService(
    name: 'Unimed',
    type: LifeItemType.insurance,
    frequency: _monthly,
  ),

  // Banking and cards
  KnownService(name: 'Revolut', type: _sub, frequency: _monthly),
  KnownService(name: 'N26', type: _sub, frequency: _monthly),
  KnownService(name: 'Wise', type: _sub, frequency: _monthly),
  KnownService(
    name: 'American Express',
    type: LifeItemType.bill,
    frequency: _yearly,
  ),

  // Press
  KnownService(name: 'Público', type: _sub, frequency: _monthly),
  KnownService(name: 'Expresso', type: _sub, frequency: _monthly),
  KnownService(name: 'Observador', type: _sub, frequency: _monthly),
  KnownService(name: 'El País', type: _sub, frequency: _monthly),
  KnownService(name: 'The New York Times', type: _sub, frequency: _monthly),
  KnownService(name: 'Medium', type: _sub, frequency: _monthly),
];
