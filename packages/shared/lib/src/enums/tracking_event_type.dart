enum TrackingEventType {
  created,
  statusChanged,
  locationUpdate,
  documentUploaded,
  paymentUpdated,
  assigned,
  noteAdded;

  String get apiValue => name;

  static TrackingEventType fromApi(String value) {
    return TrackingEventType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TrackingEventType.noteAdded,
    );
  }
}
