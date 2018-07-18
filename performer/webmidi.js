  var midiAccess;
  var selectedMidiInPort;
  var selectedMidiOutPort;
  var midiInKey = "__midi-in__";
  var midiOutKey = "__midi-out__";

  var closeMidiAccess;

  var genMidiError = function(ePair) {
    if (closeMidiAccess) {
      closeMidiAccess();
    }
    app.ports.midiError.send(ePair);
  };
  var midiError = function(e) {
    genMidiError([e.name, e.message]);
  };



  var pubRecvMidi = function(e) {
    app.ports.recvMidi.send(Array.from(e.data));
  };

  var selectMidiPort = function(selectedPort, port) {
    if (selectedPort !== port) {
      if (selectedPort) {
        selectedPort.close();
        selectedPort = null;
      }
      if (port) {
        selectedPort = port;
        let req = selectedPort.open();
        req.then(function(s){}, midiError);
      }
    }
    return selectedPort;
  };

  var selectMidiInPort = function(id) {
    localStorage.setItem(midiInKey, id);
    selectedMidiInPort = selectMidiPort(selectedMidiInPort,
                                        midiAccess.inputs.get(id));
    if (selectedMidiInPort) {
      selectedMidiInPort.onmidimessage = pubRecvMidi;
    }
  }

  var selectMidiOutPort = function(id) {
    localStorage.setItem(midiOutKey, id)
    selectedMidiOutPort = selectMidiPort(selectedMidiOutPort,
                                         midiAccess.outputs.get(id));
  }

  var pubMidiAccess = function() {
    let cvt = function(p) {
      return {
        'id': p.id,
        'manufacturer': p.manufacturer,
        'name': p.name,
        'state': p.state,
        'connection': p.connection
      };
    };

    let process = function(ports, key, selectFn)  {
      let list = [];
      let allClosed = true;
      let selection = localStorage.getItem(key);
      for (let p of ports.values()) {
        list.push(cvt(p));
        allClosed = allClosed && p.connection == "closed";
      }
      if (allClosed && selection !== null)  {
        selectFn(selection);
      }
      return list;
    };

    let inList = [];
    let outList = [];
    if (midiAccess) {
      inList = process(midiAccess.inputs, midiInKey, selectMidiInPort);
      outList = process(midiAccess.outputs, midiOutKey, selectMidiOutPort);
    }

    app.ports.midiAccess.send([inList, outList]);
  };

  var requestMidiAccess = function() {
    let setupMidiAccess = function(ma) {
      midiAccess = ma;
      midiAccess.onstatechange = pubMidiAccess;
      pubMidiAccess();
    };
    let rejected = function(e) {
      pubMidiAccess();
      midiError(e);
    }

    if (navigator.requestMIDIAccess) {
      let req = navigator.requestMIDIAccess({ 'sysex': true });
      req.then(setupMidiAccess, rejected);
    }
    else {
      let noWebMidi = function() {
        this.name = "NoWebMidi";
        this.message = "This browser doesn't support WebMIDI.";
      };
      let sendError = function() { midiError(new noWebMidi()); };
      setTimeout(sendError, 500);
    }
  };

  var closeMidiAccess = function() {
    selectMidiPort(selectedMidiInPort, null);
    selectMidiPort(selectedMidiOutPort, null);
    if (midiAccess) {
      midiAccess.onstatechange = null;
    }
    midiAccess = null;
  }

  app.ports.genMidiError.subscribe(genMidiError);
  app.ports.selectMidiIn.subscribe(selectMidiInPort);
  app.ports.selectMidiOut.subscribe(selectMidiOutPort);

  var sendMidi = function(data) {
    if (selectedMidiOutPort) {
      try {
        selectedMidiOutPort.send(data);
      }
      catch(e) {
        midiError(e);
      }
    }
  };
  app.ports.sendMidi_.subscribe(sendMidi);
  app.ports.closeMidi.subscribe(closeMidiAccess);