struct EscrowSystem {
    owner: address?;
    recipient: address?;
    amount: uint64;
    isReleased: bool;
    isRequested: bool;
}

init fun init() {
    var escrow = EscrowSystem{
        owner: null(),
        recipient: null(),
        amount: 0,
        isReleased: false,
        isRequested: false
    };
    escrow.store();
}

fun onInternalMessage(in: InMessage) {
    if (in.body.isEmpty()) {
        return; // ignore
    }

    val msg = MessageBody.fromSlice(in.body);

    match (msg) {
        InitializeEscrow => {
            val payload = msg as InitializeEscrow;
            var escrow = EscrowSystem.load();

            escrow.owner = in.senderAddress;
            escrow.recipient = payload.recipient;
            escrow.amount = payload.amount;
            escrow.isReleased = false;
            escrow.isRequested = false;

            escrow.store();
        }

        RequestFunds => {
            var escrow = EscrowSystem.load();
            assert (in.senderAddress == escrow.recipient) throw 101;
            assert (!escrow.isRequested) throw 102;

            escrow.isRequested = true;
            escrow.store();
        }

        ReleaseFunds => {
            var escrow = EscrowSystem.load();
            assert (escrow.isRequested) throw 108;
            assert (!escrow.isReleased) throw 109;
            assert (in.senderAddress == escrow.owner) throw 110;

            escrow.isReleased = true;
            escrow.store();

            val res = createMessage({
                bounce: false,
                dest: escrow.recipient!!,
                value: contract.getBalance() - 100000000u
            });
            res.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        CancelEscrow => {
            var escrow = EscrowSystem.load();
            assert (in.senderAddress == escrow.owner) throw 106;
            assert (!escrow.isReleased) throw 107;

            escrow.isReleased = true;
            escrow.store();

            val res = createMessage({
                bounce: false,
                dest: in.senderAddress,
                value: contract.getBalance() - 100000000u
            });
            res.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        else => {
            assert (in.body.isEmpty()) throw 100;
        }
    }
}

