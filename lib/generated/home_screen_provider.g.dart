// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../features/home/data/providers/home_screen_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HomeSectionDTOAdapter extends TypeAdapter<HomeSectionDTO> {
  @override
  final typeId = 3;

  @override
  HomeSectionDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HomeSectionDTO(
      title: fields[0] as String,
      contents: (fields[1] as List).cast<ContentItemDTO>(),
    );
  }

  @override
  void write(BinaryWriter writer, HomeSectionDTO obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.contents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeSectionDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentItemDTOAdapter extends TypeAdapter<ContentItemDTO> {
  @override
  final typeId = 8;

  @override
  ContentItemDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentItemDTO(
      name: fields[0] as String,
      contentType: fields[1] as String,
      playlistId: fields[2] as String,
      thumbnails: (fields[3] as List).cast<ThumbnailFullDTO>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContentItemDTO obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.contentType)
      ..writeByte(2)
      ..write(obj.playlistId)
      ..writeByte(3)
      ..write(obj.thumbnails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentItemDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlbumDetailedDTOAdapter extends TypeAdapter<AlbumDetailedDTO> {
  @override
  final typeId = 6;

  @override
  AlbumDetailedDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlbumDetailedDTO(
      name: fields[0] as String,
      contentType: fields[1] as String,
      playlistId: fields[2] as String,
      thumbnails: (fields[3] as List).cast<ThumbnailFullDTO>(),
      artist: fields[4] as ArtistBasicDTO,
      albumId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AlbumDetailedDTO obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.contentType)
      ..writeByte(2)
      ..write(obj.playlistId)
      ..writeByte(3)
      ..write(obj.thumbnails)
      ..writeByte(4)
      ..write(obj.artist)
      ..writeByte(5)
      ..write(obj.albumId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumDetailedDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaylistDetailedDTOAdapter extends TypeAdapter<PlaylistDetailedDTO> {
  @override
  final typeId = 7;

  @override
  PlaylistDetailedDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistDetailedDTO(
      name: fields[0] as String,
      contentType: fields[1] as String,
      playlistId: fields[2] as String,
      thumbnails: (fields[3] as List).cast<ThumbnailFullDTO>(),
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistDetailedDTO obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.contentType)
      ..writeByte(2)
      ..write(obj.playlistId)
      ..writeByte(3)
      ..write(obj.thumbnails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistDetailedDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArtistBasicDTOAdapter extends TypeAdapter<ArtistBasicDTO> {
  @override
  final typeId = 4;

  @override
  ArtistBasicDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtistBasicDTO(name: fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, ArtistBasicDTO obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistBasicDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThumbnailFullDTOAdapter extends TypeAdapter<ThumbnailFullDTO> {
  @override
  final typeId = 5;

  @override
  ThumbnailFullDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThumbnailFullDTO(
      url: fields[0] as String,
      width: (fields[1] as num).toInt(),
      height: (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ThumbnailFullDTO obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.width)
      ..writeByte(2)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThumbnailFullDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
