// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../features/trending/data/provider/trending_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongInfoDTOAdapter extends TypeAdapter<SongInfoDTO> {
  @override
  final typeId = 0;

  @override
  SongInfoDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongInfoDTO(
      videoId: fields[0] as String,
      name: fields[1] as String,
      artists: (fields[2] as List).cast<ArtistDTO>(),
      thumbnails: (fields[3] as List).cast<ThumbnailDTO>(),
      duration: (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SongInfoDTO obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.artists)
      ..writeByte(3)
      ..write(obj.thumbnails)
      ..writeByte(4)
      ..write(obj.duration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongInfoDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ArtistDTOAdapter extends TypeAdapter<ArtistDTO> {
  @override
  final typeId = 1;

  @override
  ArtistDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtistDTO(name: fields[0] as String, id: fields[1] as String);
  }

  @override
  void write(BinaryWriter writer, ArtistDTO obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ThumbnailDTOAdapter extends TypeAdapter<ThumbnailDTO> {
  @override
  final typeId = 2;

  @override
  ThumbnailDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThumbnailDTO(
      url: fields[0] as String,
      width: (fields[1] as num).toInt(),
      height: (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ThumbnailDTO obj) {
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
      other is ThumbnailDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
