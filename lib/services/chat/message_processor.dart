import '../../card/bus_card.dart';
import '../../card/airplane_card.dart';
import '../../card/airbnb_card.dart';
import '../../card/amazon_card.dart';
import '../../card/booking_dot_com_card.dart';
import '../../card/restaurant_card.dart';
import '../../card/fashion_shopping.dart';
import '../../card/perplexity_card.dart';
import '../../card/uber_card.dart';

// Helper to convert dynamic maps to Map<String, String>.
List<Map<String, String>> quoteKeysAndValues(dynamic response) {
  final List<dynamic> list = response as List<dynamic>;
  final List<Map<String, String>> quotedMaps = list.map((item) {
    final Map<String, dynamic> map = item as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key.toString(), value.toString()));
  }).toList();
  return quotedMaps;
}

/// Processes the server response and updates the messages list.
void processServerResponse({
  required dynamic response,
  required List<Map<String, dynamic>> messages,
}) {
  List<Map<String, String>> responseData = [];
  if (response is Map && response.containsKey("data")) {
    if (response["data"] is List) {
      responseData = quoteKeysAndValues(response["data"]);
    } else if (response["data"] is Map) {
      responseData = quoteKeysAndValues([response["data"]]);
    }
  }

  if (response is Map && response.containsKey("type")) {
    // Optional: further format data if needed.
    void addCardsToMessages<T>(
      List<Map<String, String>> response,
      String cardType,
      List<T> Function(List<Map<String, String>> response) parseCards,
    ) {
      List<T> cards = parseCards(response);
      for (var card in cards) {
        messages.add({
          "type": cardType,
          "data": card,
          "sender": "bot",
        });
      }
    }

    switch (response["type"]) {
      case "bus":
        addCardsToMessages<BusCard>(responseData, "bus", getBusCards);
        break;
      case "airplane":
        addCardsToMessages<AirplaneCard>(
            responseData, "airplane", getAirplaneCards);
        break;
      case "amazon":
        addCardsToMessages<AmazonCard>(responseData, "amazon", getAmazonCards);
        break;
      case "airbnb":
        addCardsToMessages<AirbnbCard>(responseData, "airbnb", getAirbnbCards);
        break;
      case "booking":
        addCardsToMessages<BookingCard>(
            responseData, "booking", getBookingCards);
        break;
      case "restaurant":
        addCardsToMessages<RestaurantCard>(
            responseData, "restaurant", getRestaurantCards);
        break;
      case "fashion":
        addCardsToMessages<FashionShopping>(
            responseData, "fashion", getFashionCards);
        break;
      case "perplexity":
        addCardsToMessages<PerplexityCard>(
            responseData, "perplexity", getPerplexityCards);
        break;
      case "uber":
        addCardsToMessages<UberCard>(responseData, "uber", getUberCards);
        break;
      default:
        messages.add({
          "type": "text",
          "text": response.containsKey("data")
              ? response["data"]
              : response.toString(),
          "sender": "bot",
        });
    }
  } else {
    messages.add({
      "type": "text",
      "text": response.toString(),
      "sender": "bot",
    });
  }
}
