// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracked_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceRecordAdapter extends TypeAdapter<PriceRecord> {
  @override
  final int typeId = 1;

  @override
  PriceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceRecord(
      checkedAt: fields[0] as DateTime,
      price: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PriceRecord obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.checkedAt)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrackedItemAdapter extends TypeAdapter<TrackedItem> {
  @override
  final int typeId = 0;

  @override
  TrackedItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackedItem(
      id: fields[0] as String,
      url: fields[1] as String,
      type: fields[2] as TrackedType,
      title: fields[3] as String,
      shopName: fields[4] as String?,
      imageUrl: fields[5] as String?,
      price: fields[6] as int?,
      isAvailable: fields[7] as bool,
      addedAt: fields[8] as DateTime?,
      lastCheckedAt: fields[9] as DateTime?,
      priceHistory: (fields[10] as List?)?.cast<PriceRecord>(),
      knownChildItemIds: (fields[11] as List?)?.cast<String>(),
      newItemIdsSinceLastView: (fields[12] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrackedItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.shopName)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.price)
      ..writeByte(7)
      ..write(obj.isAvailable)
      ..writeByte(8)
      ..write(obj.addedAt)
      ..writeByte(9)
      ..write(obj.lastCheckedAt)
      ..writeByte(10)
      ..write(obj.priceHistory)
      ..writeByte(11)
      ..write(obj.knownChildItemIds)
      ..writeByte(12)
      ..write(obj.newItemIdsSinceLastView);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrackedTypeAdapter extends TypeAdapter<TrackedType> {
  @override
  final int typeId = 2;

  @override
  TrackedType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TrackedType.item;
      case 1:
        return TrackedType.shop;
      default:
        return TrackedType.item;
    }
  }

  @override
  void write(BinaryWriter writer, TrackedType obj) {
    switch (obj) {
      case TrackedType.item:
        writer.writeByte(0);
        break;
      case TrackedType.shop:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
