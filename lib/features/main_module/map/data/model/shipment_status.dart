enum ShipmentStatus {
  pending,
  assigned,
  inTransit,
  completed,
  canceled,
  unknown,
}

ShipmentStatus parseShipmentStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'pending':
      return ShipmentStatus.pending;
    case 'assigned':
      return ShipmentStatus.assigned;
    case 'in_transit':
      return ShipmentStatus.inTransit;
    case 'completed':
      return ShipmentStatus.completed;
    case 'canceled':
    case 'cancelled':
      return ShipmentStatus.canceled;
    default:
      return ShipmentStatus.unknown;
  }
}
