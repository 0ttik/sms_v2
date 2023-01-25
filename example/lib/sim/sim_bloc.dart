import 'dart:async';

import 'package:sms_v2/sms.dart';

class SimCardsBloc {
  SimCardsBloc() {
    _onSimCardChanged = _streamController.stream.asBroadcastStream();
  }

  final _simCardsProvider = new SimCardsProvider();
  final _streamController = new StreamController<SimCard>();
  late Stream<SimCard> _onSimCardChanged;
  late List<SimCard> _simCards;
  late SimCard _selectedSimCard;

  Stream<SimCard> get onSimCardChanged => _onSimCardChanged;

  SimCard? get selectedSimCard => _selectedSimCard;

  Future<void> loadSimCards() async {
    _simCards = await _simCardsProvider.getSimCards();
    _simCards.forEach((sim) {
      if (sim.state == SimCardState.Ready) {
        this.selectSimCard(sim);
      }
    });
  }

  void toggleSelectedSim() async {
    _selectNextSimCard();
    _streamController.add(_selectedSimCard);
  }

  SimCard _selectNextSimCard() {
    for (var i = 0; i < _simCards.length; i++) {
      if (_simCards[i].imei == _selectedSimCard.imei) {
        if (i + 1 < _simCards.length) {
          _selectedSimCard = _simCards[i + 1];
        } else {
          _selectedSimCard = _simCards[0];
        }
        break;
      }
    }

    return _selectedSimCard;
  }

  void selectSimCard(SimCard sim) {
    _selectedSimCard = sim;
    _streamController.add(_selectedSimCard);
  }
}
