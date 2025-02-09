// lib/main.dart
// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'card/bus_card.dart';
import 'card/airplane_card.dart';
import 'card/airbnb_card.dart';
import 'card/amazon_card.dart';
import 'card/booking_dot_com_card.dart';
import 'card/restaurant_card.dart';
import 'card/fashion_shopping.dart';
import 'card/movies_list.dart';
import 'card/movies_timing.dart';
import 'card/perplexity_card.dart';
import 'card/uber_card.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const ChatApp());
}

List<Map<String, String>> history = [];

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blueAccent,
        colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Every message now includes a "sender" property.
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false; // Indicates whether a message is being processed.
  http.Client? _client; // HTTP client for making/canceling requests.

  /// Sends the message to the server and waits for the reply.
  Future<dynamic> sendString(String message) async {
    // final url = Uri.parse('https://mighty-sailfish-touched.ngrok-free.app'); // Piyush
    // final url = Uri.parse('https://stirred-bream-largely.ngrok-free.app'); // Deepanshu
    final url =
        Uri.parse('https://just-mainly-monster.ngrok-free.app'); // Siddhanth

    _client = http.Client();
    try {
      final response = await _client!
          .post(
        url,
        // headers: {"Content-Type": "application/json"},
        // body: jsonEncode({"message": message, "history": history}),
        headers: {'Content-Type': 'text/plain', 'Accept': 'application/json'},
        body: history.toString(),
      )
          .timeout(
        const Duration(seconds: 60), // Timeout to prevent infinite waiting
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      _client?.close();
      _client = null;

      if (response.statusCode == 200) {
        // debugPrint(response.body.toString());
        return jsonDecode(response.body);
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      // debugPrint('Error: $e');
      return 'Error: $e';
    }
  }

  /// Cancels the current message processing.
  void _cancelMessage() {
    // Cancel the HTTP request if still in progress.
    _client?.close();
    _client = null;
    setState(() {
      _isLoading = false;
      // Remove the loading indicator message if it exists.
      if (messages.isNotEmpty && messages.last["type"] == "loading") {
        messages.removeLast();
      }
      // Also remove the last user message that initiated the request.
      if (messages.isNotEmpty && messages.last["sender"] == "user") {
        messages.removeLast();
      }
    });
  }

  /// Called when the send (or stop) button is pressed.
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final inputText = _controller.text.trim();

    // Process clear command immediately.
    if (inputText == "clear()") {
      setState(() {
        messages.clear();
      });
      _controller.clear();
      return;
    }

    // Add the user message and disable further input.
    setState(() {
      _isLoading = true;
      messages.add({
        "type": "text",
        "text": inputText,
        "sender": "user",
      });
      history.add({"role": "user", "content": inputText});
    });

    // Add a loading indicator message.
    final int loadingMessageIndex = messages.length;
    setState(() {
      messages.add({
        "type": "loading",
        "sender": "bot",
      });
    });

    // Wait until the HTTP request completes.
    final response = await sendString(inputText);
    history.add({"role": "assistant", "content": response.toString()});

    List<Map<String, String>> quoteKeysAndValues(dynamic response) {
      // First, ensure that response is a List<dynamic>
      final List<dynamic> list = response as List<dynamic>;

      // Now, convert each element to Map<String, String>
      final List<Map<String, String>> quotedMaps = list.map((item) {
        final Map<String, dynamic> map = item as Map<String, dynamic>;
        return map
            .map((key, value) => MapEntry(key.toString(), value.toString()));
      }).toList();

      // Return the JSON-encoded string.
      return quotedMaps;
    }

    List<Map<String, String>> responseData = [];
    if (response["data"] is List) {
      responseData = quoteKeysAndValues(response["data"]);
    } else if (response["data"] is Map) {
      responseData =
          quoteKeysAndValues([response["data"]]); // Wrap it in a list
    }

    // If the request was canceled, _isLoading would be false.
    if (!_isLoading) {
      return;
    }

    // Remove the loading indicator message.
    setState(() {
      messages.removeAt(loadingMessageIndex);
    });

    // Process the server response.
    setState(() {
      if (response is String) {
        messages.add({
          "type": "text",
          "text": response,
          "sender": "bot",
        });
      } else {
        if (response["type"] == "bus") {
          addBusCardsToMessages(responseData);
        } else if (response["type"] == "airplane") {
          addAirplaneCardsToMessages(responseData);
        } else if (response["type"] == "amazon") {
          addAmazonCardsToMessages(responseData);
        } else if (response["type"] == "airbnb") {
          addAirbnbCardsToMessages(responseData);
        } else if (response["type"] == "booking") {
          addBookingCardsToMessages(responseData);
        } else if (response["type"] == "restaurant") {
          addRestaurantCardsToMessages(responseData);
        } else if (response["type"] == "fashion") {
          addFashionShoppingCardsToMessages(responseData);
        } else if (response["type"] == "movietime") {
          addMovieTimeingCardToMessages(responseData);
        } else if (response["type"] == "movieslist") {
          addMoviesListCardsToMessages(responseData);
        } else if (response["type"] == "perplexity") {
          addPerplexityCardsToMessages(responseData);
        } else if (response["type"] == "uber") {
          addUberCardsToMessages(responseData);
        } else {
          // FIX: Extract "data" from the response map if available.
          messages.add({
            "type": "text",
            "text": response is Map && response.containsKey("data")
                ? response["data"]
                : response.toString(),
            "sender": "bot",
          });
        }
      }
      _isLoading = false;
    });

    _controller.clear();
    _focusNode.requestFocus();

    // Scroll to bottom after frame updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Adds Uber card messages.
  void addUberCardsToMessages(List<Map<String, String>> response) {
    List<UberCard> uberCards = getUberCards(response);
    for (var uberCard in uberCards) {
      messages.add({
        "type": "uber",
        "data": uberCard,
        "sender": "bot",
      });
    }
  }

  /// Adds Movie Timings card messages.
  void addMovieTimeingCardToMessages(List<Map<String, String>> response) {
    List<MoviesTimingCard> moviesTimingCards = getMoviesTimingCards();
    for (var moviesTimingCard in moviesTimingCards) {
      messages.add({
        "type": "mtime",
        "data": moviesTimingCard,
        "sender": "bot",
      });
    }
  }

  /// Adds bus card messages.
  void addBusCardsToMessages(List<Map<String, String>> response) {
    List<BusCard> busCards = getBusCards(response);
    for (var busCard in busCards) {
      messages.add({
        "type": "bus",
        "data": busCard,
        "sender": "bot",
      });
    }
  }

  /// Adds airplane card messages.
  void addAirplaneCardsToMessages(List<Map<String, String>> response) {
    List<AirplaneCard> airplaneCards = getAirplaneCards(response);
    for (var airplaneCard in airplaneCards) {
      messages.add({
        "type": "airplane",
        "data": airplaneCard,
        "sender": "bot",
      });
    }
  }

  /// Adds amazon card messages.
  void addAmazonCardsToMessages(List<Map<String, String>> response) {
    List<AmazonCard> amazonCards = getAmazonCards(response);
    for (var amazonCard in amazonCards) {
      messages.add({
        "type": "amazon",
        "data": amazonCard,
        "sender": "bot",
      });
    }
  }

  /// Adds airbnb card messages.
  void addAirbnbCardsToMessages(List<Map<String, String>> response) {
    List<AirbnbCard> airbnbCards = getAirbnbCards(response);
    for (var airbnbCard in airbnbCards) {
      messages.add({
        "type": "airbnb",
        "data": airbnbCard,
        "sender": "bot",
      });
    }
  }

  /// Adds booking dot com card messages.
  void addBookingCardsToMessages(List<Map<String, String>> response) {
    List<BookingCard> bookingCards = getBookingCards(response);
    for (var bookingCard in bookingCards) {
      messages.add({
        "type": "booking",
        "data": bookingCard,
        "sender": "bot",
      });
    }
  }

  /// Adds restaurant card messages.
  void addRestaurantCardsToMessages(List<Map<String, String>> response) {
    List<RestaurantCard> restaurantCards = getRestaurantCards(response);
    for (var restaurantCard in restaurantCards) {
      messages.add({
        "type": "restaurant",
        "data": restaurantCard,
        "sender": "bot",
      });
    }
  }

  /// Adds fashion shopping card messages.
  void addFashionShoppingCardsToMessages(List<Map<String, String>> response) {
    List<FashionShopping> fashionCards = getFashionCards(response);
    for (var fashionCard in fashionCards) {
      messages.add({
        "type": "fashion",
        "data": fashionCard,
        "sender": "bot",
      });
    }
  }

  /// Adds movies list card messages.
  void addMoviesListCardsToMessages(List<Map<String, String>> response) {
    List<MovieList> moviesCards = getMoviesListCards();
    for (var moviesCard in moviesCards) {
      messages.add({
        "type": "movieslist",
        "data": moviesCard,
        "sender": "bot",
      });
    }
  }

  /// Adds perplexity card messages.
  void addPerplexityCardsToMessages(List<Map<String, String>> response) {
    List<PerplexityCard> perplexityCards = getPerplexityCards(response);
    for (var perplexityCard in perplexityCards) {
      messages.add({
        "type": "perplexity",
        "data": perplexityCard,
        "sender": "bot",
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.7;

    /// Helper to wrap a message widget with an icon.
    Widget buildMessageWithIcon(Widget messageWidget, int index, bool isUser) {
      bool showIcon = true;
      if (index > 0) {
        final prevMsg = messages[index - 1];
        if (prevMsg["sender"] == messages[index]["sender"]) {
          showIcon = false;
        }
      }

      const double iconAreaWidth = 40.0;
      const double spacing = 8.0;
      Widget iconWidget;
      if (showIcon) {
        if (isUser) {
          iconWidget = Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
              padding: const EdgeInsets.all(4.0),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                size: 30.0,
                color: Colors.white,
              ),
            ),
          );
        } else {
          iconWidget = Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[800],
              ),
              padding: const EdgeInsets.all(4.0),
              alignment: Alignment.center,
              child: Icon(
                Icons.smart_toy_rounded,
                size: 30.0,
                color: Colors.white,
              ),
            ),
          );
        }
      } else {
        iconWidget = const SizedBox(width: iconAreaWidth);
      }

      if (isUser) {
        return Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: messageWidget),
              const SizedBox(width: spacing),
              SizedBox(width: iconAreaWidth, child: iconWidget),
            ],
          ),
        );
      } else {
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: iconAreaWidth, child: iconWidget),
              const SizedBox(width: spacing),
              Flexible(child: messageWidget),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ATHENA",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "nasa"),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.replay_circle_filled_outlined, color: Colors.white),
          iconSize: 32,
          onPressed: () {
            setState(() {
              messages.clear();
              history.clear();
            });
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final String sender = msg["sender"] ?? "bot";
                final bool isUser = sender == "user";

                if (msg["type"] == "text") {
                  final bubble = ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blueAccent : Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg["text"].toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ).animate().fade(duration: 300.ms).slideX(
                        begin: isUser ? 1 : -1,
                      );
                  return buildMessageWithIcon(bubble, index, isUser);
                } else if (msg["type"] == "loading") {
                  final bubble = ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 300.ms).slideX(
                        begin: isUser ? 1 : -1,
                      );
                  return buildMessageWithIcon(bubble, index, isUser);
                }
                // Card messages...
                else if (msg["type"] == "bus") {
                  final busCard = msg["data"] as BusCard;
                  return buildMessageWithIcon(busCard, index, isUser);
                } else if (msg["type"] == "airplane") {
                  final airplaneCard = msg["data"] as AirplaneCard;
                  return buildMessageWithIcon(airplaneCard, index, isUser);
                } else if (msg["type"] == "amazon") {
                  final amazonCard = msg["data"] as AmazonCard;
                  return buildMessageWithIcon(amazonCard, index, isUser);
                } else if (msg["type"] == "airbnb") {
                  final airbnbCard = msg["data"] as AirbnbCard;
                  return buildMessageWithIcon(airbnbCard, index, isUser);
                } else if (msg["type"] == "booking") {
                  final bookingCard = msg["data"] as BookingCard;
                  return buildMessageWithIcon(bookingCard, index, isUser);
                } else if (msg["type"] == "restaurant") {
                  final restaurantCard = msg["data"] as RestaurantCard;
                  return buildMessageWithIcon(restaurantCard, index, isUser);
                } else if (msg["type"] == "fashion") {
                  final fashionCard = msg["data"] as FashionShopping;
                  return buildMessageWithIcon(fashionCard, index, isUser);
                } else if (msg["type"] == "movieslist") {
                  final movieslist = msg["data"] as MovieList;
                  return buildMessageWithIcon(movieslist, index, isUser);
                } else if (msg["type"] == "mtime") {
                  final movietimes = msg["data"] as MoviesTimingCard;
                  return buildMessageWithIcon(movietimes, index, isUser);
                } else if (msg["type"] == "perplexity") {
                  final perplexity = msg["data"] as PerplexityCard;
                  return buildMessageWithIcon(perplexity, index, isUser);
                } else if (msg["type"] == "uber") {
                  final uberCard = msg["data"] as UberCard;
                  return buildMessageWithIcon(uberCard, index, isUser);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment
                  .center, // Align items in the center vertically
              children: [
                // TextField wrapped in SizedBox
                Expanded(
                  child: SizedBox(
                    height:
                        56, // Match FloatingActionButton's default height (56)
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !_isLoading,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (value) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: "Ask something...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: _isLoading ? Colors.grey : Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20, // Adjust padding for better alignment
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Space between TextField and button
                // FloatingActionButton wrapped in a SizedBox
                SizedBox(
                  height: 56, // Match default FAB height
                  width: 56, // Match default FAB width
                  child: FloatingActionButton(
                    backgroundColor: _isLoading ? Colors.red : Colors.blueAccent,
                    onPressed: _isLoading ? _cancelMessage : _sendMessage,
                    child: Icon(
                      _isLoading ? Icons.stop : Icons.send,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
