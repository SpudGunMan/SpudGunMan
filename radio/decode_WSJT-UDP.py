# WSJT UDP message listener and decoder for multicast.
# Uses QDataStream-compatible binary decoding for schema 2.
# DE K7MHI

import datetime
import socket
import struct
import sys

mcast_group = '224.0.0.1'
mcast_port = 2237

print("Starting WSJT multicast listener")
print("Make sure WSJT is configured to send UDP messages to IP/group and port.")
print("WSJT configuration: Settings -> Reporting -> UDP Server")
print("Set IP to Multicast group:", mcast_group, "port:", mcast_port)
print("Some Linux distributions may need 'sudo ip link set lo multicast on'")
print("Waiting for messages...")

class QtDataStreamReader:
    def __init__(self, data):
        self.data = data
        self.pos = 0

    def _read(self, fmt):
        size = struct.calcsize(fmt)
        if self.pos + size > len(self.data):
            raise ValueError("unexpected end of data")
        value = struct.unpack('>' + fmt, self.data[self.pos:self.pos + size])
        self.pos += size
        return value[0] if len(value) == 1 else value

    def read_uint32(self):
        return self._read('I')

    def read_int32(self):
        return self._read('i')

    def read_int64(self):
        return self._read('q')

    def read_uint64(self):
        return self._read('Q')

    def read_uint8(self):
        return self._read('B')

    def read_double(self):
        return self._read('d')

    def read_bool(self):
        return bool(self._read('B'))

    def read_bytes(self, length):
        if self.pos + length > len(self.data):
            raise ValueError("unexpected end of data")
        value = self.data[self.pos:self.pos + length]
        self.pos += length
        return value

    def read_qbytearray(self):
        size = self.read_uint32()
        if size == 0xffffffff:
            return None
        return self.read_bytes(size)

    def read_utf8(self):
        raw = self.read_qbytearray()
        return None if raw is None else raw.decode('utf-8', errors='replace')

    def read_qtime(self):
        ms = self.read_uint32()
        if ms == 0xffffffff:
            return None
        hour = ms // 3600000
        minute = (ms % 3600000) // 60000
        second = (ms % 60000) // 1000
        msec = ms % 1000
        return datetime.time(hour, minute, second, msec * 1000)

    def read_qcolor(self):
        raw = self.read_qbytearray()
        return None if raw is None else raw.hex()

    def read_qdate(self):
        julian_day = self.read_int64()
        if julian_day == -1:
            return None
        j = julian_day + 68569
        n = (4 * j) // 146097
        j = j - (146097 * n + 3) // 4
        i = (4000 * (j + 1)) // 1461000
        j = j - (1461 * i) // 4 + 31
        k = (80 * j) // 2447
        day = j - (2447 * k) // 80
        j = k // 11
        month = k + 2 - 12 * j
        year = 100 * (n - 49) + i + j
        return datetime.date(year, month, day)

    def read_qdatetime(self):
        date = self.read_qdate()
        time = self.read_qtime()
        timespec = self.read_uint8()
        if timespec == 2:
            offset_seconds = self.read_int32()
        elif timespec == 3:
            # Qt QTimeZone serialization is complex; skip extra timezone fields.
            _zone_id = self.read_utf8()
            _zone_offset = self.read_int32()
            _zone_name = self.read_utf8()
        if date is None or time is None:
            return None
        return datetime.datetime.combine(date, time)


def decode_message(data):
    reader = QtDataStreamReader(data)
    magic = reader.read_uint32()
    if magic != 0xadbccbda:
        raise ValueError("bad magic number 0x%08x" % magic)

    schema = reader.read_uint32()
    if schema != 2:
        raise ValueError("unsupported schema %d" % schema)

    message_type = reader.read_uint32()
    message_id = reader.read_utf8()
    return message_type, message_id, reader


def format_qtime(qtime):
    if qtime is None:
        return "<invalid>"
    return qtime.strftime('%H:%M:%S.%f')[:-3]


try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((mcast_group, mcast_port))
    print("Socket bound to", (mcast_group, mcast_port))

    mreq = socket.inet_aton(mcast_group) + socket.inet_aton('0.0.0.0')
    sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
    print("Joined multicast group", mcast_group)
except Exception as e:
    print("Socket setup failed:", repr(e))
    sys.exit(1)

while True:
    data, addr = sock.recvfrom(10240)
    print("=== packet ===")
    print("Source:", addr, "length:", len(data))
    print("Raw bytes:", data[:64].hex(), "..." if len(data) > 64 else "")

    try:
        message_type, message_id, reader = decode_message(data)
        print("id:", repr(message_id))
        print("message type:", message_type, end=' ')

        if message_type == 0:
            print("(heartbeat)")
            max_schema = reader.read_uint32()
            print("max_schema:", max_schema)
            version = reader.read_utf8()
            print("version:", version)
            revision = reader.read_utf8()
            print("revision:", revision)

        elif message_type == 1:
            print("(status)")
            dial_freq = reader.read_uint64()
            mode = reader.read_utf8()
            dx_call = reader.read_utf8()
            report = reader.read_utf8()
            tx_mode = reader.read_utf8()
            tx_enabled = reader.read_bool()
            transmitting = reader.read_bool()
            decoding = reader.read_bool()
            rx_df = reader.read_uint32()
            tx_df = reader.read_uint32()
            de_call = reader.read_utf8()
            de_grid = reader.read_utf8()
            dx_grid = reader.read_utf8()
            tx_watchdog = reader.read_bool()
            submode = reader.read_utf8()
            fast_mode = reader.read_bool()
            special_op_mode = reader.read_uint8()
            freq_tolerance = reader.read_uint32()
            tr_period = reader.read_uint32()
            config_name = reader.read_utf8()
            tx_message = reader.read_utf8()
            print("dial freq:", dial_freq)
            print("mode:", mode)
            print("dx call:", dx_call)
            print("report:", report)
            print("tx mode:", tx_mode)
            print("tx enabled:", tx_enabled)
            print("transmitting:", transmitting)
            print("decoding:", decoding)
            print("rx df:", rx_df)
            print("tx df:", tx_df)
            print("de call:", de_call)
            print("de grid:", de_grid)
            print("dx grid:", dx_grid)
            print("tx watchdog:", tx_watchdog)
            print("submode:", submode)
            print("fast mode:", fast_mode)
            print("special op mode:", special_op_mode)
            print("freq tolerance:", freq_tolerance)
            print("t/r period:", tr_period)
            print("config name:", config_name)
            print("tx message:", tx_message)

        elif message_type == 3:
            print("(clear)")
            window = reader.read_uint8()
            print("window:", window)

        elif message_type == 4:
            print("(reply)")
            time = reader.read_qtime()
            snr = reader.read_int32()
            delta_time = reader.read_double()
            delta_frequency = reader.read_uint32()
            mode = reader.read_utf8()
            message = reader.read_utf8()
            low_confidence = reader.read_bool()
            modifiers = reader.read_uint8()
            print("time:", format_qtime(time))
            print("snr:", snr)
            print("delta time:", delta_time)
            print("delta frequency:", delta_frequency)
            print("mode:", mode)
            print("message:", message)
            print("low confidence:", low_confidence)
            print("modifiers:", modifiers)

        elif message_type == 5:
            print("(qso logged)")
            qso_datetime = reader.read_qdatetime()
            dx_call = reader.read_utf8()
            dx_grid = reader.read_utf8()
            tx_freq = reader.read_uint64()
            mode = reader.read_utf8()
            report_sent = reader.read_utf8()
            report_recv = reader.read_utf8()
            tx_power = reader.read_utf8()
            comments = reader.read_utf8()
            name = reader.read_utf8()
            qso_datetime_on = reader.read_qdatetime()
            operator_call = reader.read_utf8()
            my_call = reader.read_utf8()
            my_grid = reader.read_utf8()
            exchange_sent = reader.read_utf8()
            exchange_recv = reader.read_utf8()
            adif_propagation = reader.read_utf8()
            print("datetime off:", qso_datetime)
            print("dx call:", dx_call)
            print("dx grid:", dx_grid)
            print("tx freq:", tx_freq)
            print("mode:", mode)
            print("report sent:", report_sent)
            print("report recv:", report_recv)
            print("tx power:", tx_power)
            print("comments:", comments)
            print("name:", name)
            print("datetime on:", qso_datetime_on)
            print("operator call:", operator_call)
            print("my call:", my_call)
            print("my grid:", my_grid)
            print("exchange sent:", exchange_sent)
            print("exchange recv:", exchange_recv)
            print("adif propagation:", adif_propagation)

        elif message_type == 6:
            print("(close)")

        elif message_type == 7:
            print("(replay)")

        elif message_type == 8:
            print("(halt tx)")
            auto_tx_only = reader.read_bool()
            print("auto tx only:", auto_tx_only)

        elif message_type == 9:
            print("(free text)")
            text = reader.read_utf8()
            send = reader.read_bool()
            print("text:", text)
            print("send:", send)

        elif message_type == 10:
            print("(wspr decode)")
            is_new = reader.read_bool()
            time = reader.read_qtime()
            snr = reader.read_int32()
            delta_time = reader.read_double()
            frequency = reader.read_uint64()
            drift = reader.read_int32()
            callsign = reader.read_utf8()
            grid = reader.read_utf8()
            power = reader.read_int32()
            off_air = reader.read_bool()
            print("new:", is_new)
            print("time:", format_qtime(time))
            print("snr:", snr)
            print("delta time:", delta_time)
            print("frequency:", frequency)
            print("drift:", drift)
            print("callsign:", callsign)
            print("grid:", grid)
            print("power:", power)
            print("off air:", off_air)

        elif message_type == 11:
            print("(location)")
            location = reader.read_utf8()
            print("location:", location)

        elif message_type == 12:
            print("(logged adif)")
            adif_text = reader.read_utf8()
            print("adif text:", adif_text)

        elif message_type == 13:
            print("(highlight callsign in)")
            callsign = reader.read_utf8()
            bg_color = reader.read_qcolor()
            fg_color = reader.read_qcolor()
            highlight_last = reader.read_bool()
            print("callsign:", callsign)
            print("background color:", bg_color)
            print("foreground color:", fg_color)
            print("highlight last:", highlight_last)

        elif message_type == 14:
            print("(switch configuration)")
            config_name = reader.read_utf8()
            print("configuration name:", config_name)

        elif message_type == 15:
            print("(configure)")
            mode = reader.read_utf8()
            freq_tolerance = reader.read_uint32()
            submode = reader.read_utf8()
            fast_mode = reader.read_bool()
            tr_period = reader.read_uint32()
            rx_df = reader.read_uint32()
            dx_call = reader.read_utf8()
            dx_grid = reader.read_utf8()
            generate_messages = reader.read_bool()
            print("mode:", mode)
            print("frequency tolerance:", freq_tolerance)
            print("submode:", submode)
            print("fast mode:", fast_mode)
            print("t/r period:", tr_period)
            print("rx df:", rx_df)
            print("dx call:", dx_call)
            print("dx grid:", dx_grid)
            print("generate messages:", generate_messages)

        elif message_type == 16:
            print("(annotation info)")
            dx_call = reader.read_utf8()
            sort_order_provided = reader.read_bool()
            sort_order = reader.read_uint32()
            print("dx call:", dx_call)
            print("sort order provided:", sort_order_provided)
            print("sort order:", sort_order)

        elif message_type == 2:
            print("(decode)")
            is_new = reader.read_bool()
            time = reader.read_qtime()
            snr = reader.read_int32()
            delta_time = reader.read_double()
            delta_frequency = reader.read_uint32()
            mode = reader.read_utf8()
            message = reader.read_utf8()
            low_confidence = reader.read_bool()
            off_air = reader.read_bool()
            print("new:", is_new)
            print("time:", format_qtime(time))
            print("snr:", snr)
            print("delta time:", delta_time)
            print("delta frequency:", delta_frequency)
            print("mode:", mode)
            print("message:", message)
            print("low confidence:", low_confidence)
            print("off air:", off_air)

        elif message_type == 6:
            print("(close)")

        else:
            print("(unknown type)")

    except Exception as e:
        print("Error decoding WSJT-X data:", e)
    print()
