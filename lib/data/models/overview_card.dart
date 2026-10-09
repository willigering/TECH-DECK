class OverviewCard {
  const OverviewCard({
    required this.title,
    required this.description,
    required this.asset,
    required this.keywords,
  });

  final String title;
  final String description;
  final String asset;
  final String keywords;

  bool matches(String query) {
    final text = '$title $description $keywords'.toLowerCase();
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .every(text.contains);
  }
}

const overviewCards = [
  OverviewCard(
    title: 'APIPA',
    description: 'Automatische IP-Adressierung ohne DHCP-Antwort',
    asset: 'assets/overview_cards/apipa.png',
    keywords: 'Netzwerke IPv4 DHCP ARP Link-Local 169.254 Subnetzmaske',
  ),
  OverviewCard(
    title: 'DNS-Hierarchie',
    description: 'Von der Root bis zum Hostnamen',
    asset: 'assets/overview_cards/dns_hierarchie.png',
    keywords: 'Netzwerke Domain Namensauflösung TLD Baumdiagramm',
  ),
  OverviewCard(
    title: 'OSI-Modell',
    description: 'Sieben Schichten mit Aufgaben und Beispielen',
    asset: 'assets/overview_cards/osi_modell.png',
    keywords: 'Netzwerke Schichtenmodell TCP UDP IP Switch Router',
  ),
];
