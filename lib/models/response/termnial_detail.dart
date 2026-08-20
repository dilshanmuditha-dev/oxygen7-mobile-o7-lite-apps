import 'merchant.dart';
import 'route.dart';

class TerminalDetail {
  String? terminalId;
  final List<Route> routes;
  final Merchant merchant;

  TerminalDetail({
    this.terminalId,
    required this.routes,
    required this.merchant,
  });

  factory TerminalDetail.fromJson(Map<String, dynamic> json) => TerminalDetail(
        terminalId: json["terminal_id"],
        routes: List<Route>.from(json["routes"].map((x) => Route.fromJson(x))),
        merchant: Merchant.fromJson(json["merchant"]),
      );

  Map<String, dynamic> toJson() => {
        "terminal_id": terminalId,
        "routes": List<dynamic>.from(routes.map((x) => x.toJson())),
        "merchant": merchant.toJson(),
      };
}
