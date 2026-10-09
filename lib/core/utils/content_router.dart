import 'package:flutter/material.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import '../../features/artist/presentation/screens/artist_content.dart';
import '../../features/playlist_album_content/presentation/screens/playlist_album_content_screen.dart';

class ContentRouter extends StatelessWidget {
  final dynamic content;

  const ContentRouter({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (content is ArtistDetailed) {
      return ArtistContent(artist: content);
    } else {
      return PlaylistAlbumContent(content: content);
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/content':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ContentRouter(content: args['content']),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
