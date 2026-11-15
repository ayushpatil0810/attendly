enum ThresholdStatus {
  meeting,
  below,
  notAvailable;

  bool get isMeeting => this == ThresholdStatus.meeting;
  bool get isBelow => this == ThresholdStatus.below;
  bool get isNotAvailable => this == ThresholdStatus.notAvailable;
}
