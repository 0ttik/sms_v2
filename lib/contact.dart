import 'dart:async';
import 'package:flutter/services.dart';

/// Class that represents the photo of a [Contact]
class Photo {
  final Uri _uri;
  final bool _isFullSize;
  Uint8List? _bytes;

  /// Gets the bytes of the photo.
  Uint8List get bytes {
    assert(_bytes != null);
    return _bytes!;
  }

  Photo(this._uri, {bool isFullSize = false}) : _isFullSize = isFullSize;

  /// Read async the bytes of the photo.
  Future<Uint8List> _readBytes() async {
    late final Uint8List bytes;
    if (this._bytes == null) {
      final photoQuery = ContactPhotoQuery();
      bytes = await photoQuery.queryContactPhoto(this._uri, fullSize: _isFullSize);
    }
    _bytes = bytes;
    return bytes;
  }
}

/// A contact's photo query
class ContactPhotoQuery {
  static ContactPhotoQuery? _instance;
  final MethodChannel _channel;

  factory ContactPhotoQuery() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel(
        "plugins.babariviere.com/queryContactPhoto",
        const StandardMethodCodec(),
      );
      _instance = new ContactPhotoQuery._private(methodChannel);
    }
    return _instance!;
  }

  ContactPhotoQuery._private(this._channel);

  /// Get the bytes of the photo specified by [uri].
  /// To get the full size of contact's photo the optional
  /// parameter [fullSize] must be set to true. By default
  /// the returned photo is the thumbnail representation of
  /// the contact's photo.
  Future<Uint8List> queryContactPhoto(Uri uri, {bool fullSize = false}) async {
    return await _channel
        .invokeMethod("getContactPhoto", {"photoUri": uri.path, "fullSize": fullSize});
  }
}

/// A contact of yours
class Contact {
  String? _fullName;
  String? _firstName;
  String? _lastName;
  String _address;
  Photo? _thumbnail;
  Photo? _photo;

  Contact({
    required String address,
    String? firstName,
    String? lastName,
    String? fullName,
    Photo? thumbnail,
    Photo? photo,
  }) : _address = address {
    this._firstName = firstName;
    this._lastName = lastName;
    assert(_fullName != null || _firstName != null && _lastName != null);
    if (fullName == null) {
      this._fullName = _firstName! + " " + _lastName!;
    } else {
      this._fullName = fullName;
    }
    this._thumbnail = thumbnail;
    this._photo = photo;
  }

  factory Contact.fromJson(String address, Map data) {
    final thumbnail = data['thumbnail'];
    return Contact(
      address: address,
      firstName: data['first'],
      lastName: data['last'],
      fullName: data['name'],
      photo: data['photo'],
      thumbnail: thumbnail == null ? null : Photo(Uri.parse(thumbnail), isFullSize: true),
    );
  }

  /// Gets the full name of the [Contact]
  String? get fullName => this._fullName;

  String? get firstName => this._firstName;

  String? get lastName => this._lastName;

  /// Gets the address of the [Contact] (the phone number)
  String get address => this._address;

  /// Gets the full size photo of the [Contact] if any, otherwise returns null.
  Photo? get photo => this._photo;

  /// Gets the thumbnail representation of the [Contact] photo if any,
  /// otherwise returns null.
  Photo? get thumbnail => this._thumbnail;
}

/// Called when sending SMS failed
typedef void ContactHandlerFail(Object e);

/// A contact query
class ContactQuery {
  static ContactQuery? _instance;
  final MethodChannel _channel;
  static Map<String, Contact> queried = {};
  static Map<String, bool> inProgress = {};

  factory ContactQuery() {
    if (_instance == null) {
      final MethodChannel methodChannel =
          const MethodChannel("plugins.babariviere.com/queryContact", const JSONMethodCodec());
      _instance = new ContactQuery._private(methodChannel);
    }
    return _instance!;
  }

  ContactQuery._private(this._channel);

  Future<Contact?> queryContact(String address) async {
    if (queried.containsKey(address) && queried[address] != null) {
      return queried[address];
    }
    if (inProgress.containsKey(address) && inProgress[address] == true) {
      throw ("already requested");
    }
    inProgress[address] = true;
    final val = await _channel.invokeMethod(
      "getContact",
      {"address": address},
    );
    Contact contact = new Contact.fromJson(address, val);
    final thumbnail = contact.thumbnail;
    if (thumbnail != null) {
      await thumbnail._readBytes();
    }
    final photo = contact.photo;
    if (photo != null) {
      await photo._readBytes();
    }
    queried[address] = contact;
    inProgress[address] = false;
    return contact;
  }
}

/// Class that represents the data of the device's owner.
class UserProfile {
  String? _fullName;
  Photo? _photo;
  Photo? _thumbnail;
  List<String> _addresses;

  UserProfile({
    List<String> addresses = const [],
    String? fullName,
    Photo? thumbnail,
    Photo? photo,
  })  : _addresses = addresses,
        _fullName = fullName,
        _thumbnail = thumbnail,
        _photo = photo;

  factory UserProfile._fromJson(Map data) {
    final addresses = data['addresses'];
    final photo = data['photo'];
    final thumbnail = data['thumbnail'];
    return UserProfile(
      addresses: addresses == null ? [] : List.from(addresses),
      fullName: data['name'],
      thumbnail: thumbnail == null ? null : Photo(Uri.parse(thumbnail)),
      photo: photo == null ? null : Photo(Uri.parse(photo)),
    );
  }

  /// Gets the full name of the [UserProfile]
  String? get fullName => _fullName;

  /// Gets the full size photo of the [UserProfile] if any,
  /// otherwise returns null.
  Photo? get photo => _photo;

  /// Gets the thumbnail representation of the [UserProfile] photo if any,
  /// otherwise returns null.
  Photo? get thumbnail => _thumbnail;

  /// Gets the collection of phone numbers of the [UserProfile]
  List<String> get addresses => _addresses;
}

/// Used to get the user profile
class UserProfileProvider {
  static UserProfileProvider? _instance;
  final MethodChannel _channel;

  factory UserProfileProvider() {
    if (_instance == null) {
      final MethodChannel methodChannel =
          const MethodChannel("plugins.babariviere.com/userProfile", const JSONMethodCodec());
      _instance = new UserProfileProvider._private(methodChannel);
    }
    return _instance!;
  }

  UserProfileProvider._private(this._channel);

  /// Returns the [UserProfile] data.
  Future<UserProfile> getUserProfile() async {
    return await _channel.invokeMethod("getUserProfile").then((dynamic val) async {
      if (val == null)
        return new UserProfile();
      else {
        final userProfile = UserProfile._fromJson(val);
        final thumbnail = userProfile.thumbnail;
        if (thumbnail != null) {
          await thumbnail._readBytes();
        }
        final photo = userProfile.photo;
        if (photo != null) {
          await photo._readBytes();
        }
        return userProfile;
      }
    });
  }
}
