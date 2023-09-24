# vim: set foldmethod=marker

from __future__ import annotations

import json
import os
import pprint
import re
import socket
import typing
from typing import Self

from libqtile import bar
from libqtile import extension
from libqtile import hook
from libqtile import layout
from libqtile import qtile
from libqtile import widget
from libqtile.config import Click
from libqtile.config import Drag
from libqtile.config import EzKey
from libqtile.config import Group
from libqtile.config import Key
from libqtile.config import KeyChord
from libqtile.config import Match
from libqtile.config import Screen
from libqtile.config import ScreenRect
from libqtile.lazy import lazy
from libqtile.log_utils import logger
from libqtile.utils import send_notification
from libqtile.widget import battery as widget_battery
from path import Path
from plasma import layout as plasma_layout
from plasma.node import Node as PlasmaNode  # type: ignore reportGeneralTypeIssues

if typing.TYPE_CHECKING:
    from collections.abc import Generator

    from libqtile.backend.base import _Window as WindowBase
    from libqtile.core.manager import Qtile

try:
    import psutil
except ImportError:
    psutil = None

if socket.gethostname() == "dellbro":
    pc = "dellbro"
else:
    pc = "default"

alt = "mod1"
win = "mod4"
mod = "mod4"
shi = "shift"
ctl = "control"

run_terminal = "app alacritty Alacritty"

run_terminal_tabbed = [
    "app",
    "tabbed -d -c -r 2 -T white -t #5f5f00 -U grey -u #171717 alacritty --embed x",
    "Alacritty",
]
# run_terminal = 'tabbed -d -c -r 2 -T white -t #5f5f00 -U grey -u #171717 app alacritty --embed ""'


# HELPERS
def is_tx(name: str) -> bool:
    return bool(
        re.match(r"^T\d+", name),
    )


def tx_groups(qtile: Qtile) -> Generator:
    for group in qtile.groups:
        if is_tx(group.name):
            yield group


class State:
    _state: dict[str, typing.Any]

    def __init__(self: Self) -> None:
        self._state_file = f"/run/user/{os.getuid()}/qtile-plasma-state.json"
        self.init()
        self._locked = True

    def init(self: Self) -> None:
        self._state = {
            "window": {},
        }

    def unlock(self: Self) -> None:
        self._locked = False

    def save(self: Self) -> None:
        if self._locked:
            return

        logger.warn(f"SAVE STATE LOCKED={self._locked}")
        data = json.dumps(self._state, indent=2, sort_keys=True)

        with Path(self._state_file).open("w") as fp:
            fp.write(data)

    def load(self: Self) -> None:
        try:
            with Path(self._state_file).open() as fp:
                self._state = json.load(fp)
        except FileNotFoundError:
            self.init()

    # def set(self: Self, kind: str, key: str, prop: str, value: typing.Any) -> None:
    #     if self._locked:
    #         return
    #
    #     kind = str(kind)
    #     key = str(key)
    #     prop = str(prop)
    #
    #     logger.warn(f"Set {kind} {key} {prop}={value}")
    #
    #     wprop = self._state[kind].setdefault(str(key), {})
    #     wprop[str(prop)] = value
    #
    # def get(self, kind: str, key: str, prop: str):
    #     kind = str(kind)
    #     key = str(key)
    #     prop = str(key)
    #
    #     if key not in self._state[kind]:
    #         return None
    #
    #     wprop = self._state["window"].get(str(key), None)
    #     if not wprop:
    #         return None
    #
    #     return wprop.get(prop, None)
    #
    # def set_window(self, wid: str, prop: str, value: typing.Any):
    #     return self.set("window", wid, prop, value)
    #
    # def get_window(self, wid: str, prop: str):
    #     return self.get("window", wid, prop)

    def del_window(self: Self, wid: int) -> None:
        widstr = str(wid)
        self._state["window"].pop(widstr, None)

    def set_group_structure(self: typing.Self, group: str, structure: dict[str, typing.Any]) -> None:
        if self._locked:
            return

        self._state.setdefault("structure", {})
        self._state["structure"][group] = structure

    def set_focus(self: Self, wid: int) -> None:
        if not self._locked:
            self._state["focused"] = wid


state = State()
state.load()


class AltTabber:
    def __init__(self, group) -> None:
        self._last = None
        self.group = group

    def focus_forward(self):
        wins = self.group.windows

        if self._last is None:
            nxt = 0
        else:
            try:
                cur = wins.index(self._last)
            except ValueError:
                cur = -1

            nxt = cur + 1

            if len(wins) == nxt:
                nxt = 0

        win = wins[nxt]

        self.group.focus(win)


class PlasmaNode(PlasmaNode):
    def reset_size(self):
        logger.warn(f"NODE RESET SIZE FROM HACK FROM {self._size} to {self.payload}")

        super().reset_size()

        if self.payload:
            state.del_window(self.payload.wid)
            state.save()

    def move(self, direction):
        ret = super().move(direction)
        self.dump_structure()
        return ret

    def integrate(self, direction):
        ret = super().integrate(direction)
        self.dump_structure()
        return ret

    def add_node(self, node, mode=None):
        ret = super().add_node(node, mode)
        self.dump_structure()
        return ret

    def add_child(self, node, idx=None):
        ret = super().add_child(node, idx)
        self.dump_structure()
        return ret

    def remove_child(self, node):
        ret = super().remove_child(node)
        self.dump_structure()
        return ret

    def replace_child(self, old, new):
        ret = super().replace_child(old, new)
        self.dump_structure()
        return ret

    def remove(self):
        ret = super().remove()
        self.dump_structure()
        return ret

    @staticmethod
    def fit_into(nodes, space):
        return PlasmaNode.fit_into(nodes, space)

    def dump_structure(self):  # noqa: C901
        if self.root.payload:
            structure = {
                "size": self.root.size,
                "wid": self.root.payload.wid,
            }
        elif self.root.children:
            structure = {
                "size": self.root.size,
                "childs": [],
            }
            if self.root.flexible:
                structure.pop("size")

            stack = []
            for child in self.root.children:
                stack.append((structure["childs"], child))

            while stack:
                parent_childs, item = stack.pop(0)
                if item.payload:
                    parent_childs.append({
                        "size": item.size,
                        "wid": item.payload.wid,
                    })
                    if item.flexible:
                        parent_childs[-1].pop("size")
                elif item.children:
                    parent_childs.append({
                        "size": item.size,
                        "childs": [],
                    })
                    if item.flexible:
                        parent_childs[-1].pop("size")
                    for child in item.children:
                        stack.append((parent_childs[-1]["childs"], child))

        else:
            structure = {}

        if self.root:
            state.set_group_structure(self.root.layout_name, structure)  # type: ignore reportGeneralTypeIssues
            state.save()


plasma_layout.Node = PlasmaNode
plasma_layout.Node.fit_into = PlasmaNode.fit_into


def quaketoggle(qtile):
    ori_group = getattr(qtile, "_original_tx_group", None)
    cur_group = qtile.current_screen.group

    if is_tx(cur_group.name):
        qtile._target_tx = cur_group.name  # noqa: SLF001
        if not ori_group:
            logger.warn("not found ori group, using previous")
            ori_group = qtile.current_screen.previous_group
        qtile.current_screen.set_group(ori_group)
        return None

    target_tx = getattr(qtile, "_target_tx", "T00")
    qtile._original_tx_group = qtile.current_screen.group  # noqa: SLF001

    tx_group = qtile.groups_map[target_tx]
    return qtile.current_screen.set_group(tx_group)


def new_tx(qtile):
    t_groups = []
    t_max_idx = 0

    for group in tx_groups(qtile):
        idx = int(group.name.lstrip("T"))
        t_max_idx = max(t_max_idx, idx)
        t_groups.append(group)

    t_next_idx = t_max_idx + 1

    logger.info(f"Total T groups: {len(t_groups)}, last {t_max_idx}")

    newname = f"T{t_next_idx:02d}"
    qtile.add_group(name=newname)

    qtile.groups_map[newname].cmd_toscreen()


def tx_select(qtile, direction):
    tx_groups_lst = list(tx_groups(qtile))
    try:
        cur_index = tx_groups_lst.index(qtile.current_group)
        nxt_index = cur_index + direction

        if nxt_index < 0:
            nxt_index = len(tx_groups_lst) - 1
        elif nxt_index >= len(tx_groups_lst):
            nxt_index = 0

        # if nxt_index < 0 or nxt_index >= len(tx_groups_lst):

    except ValueError:
        nxt_index = 0

    group = tx_groups_lst[nxt_index]
    group.cmd_toscreen()


def tx_prev(qtile):
    tx_select(qtile, -1)


def tx_next(qtile):
    tx_select(qtile, 1)


def tune_width(qtile, direction):
    screen_width = qtile.current_screen.width
    width_steps = [
        screen_width * step for step in [
            0.1, 0.15, 0.2, 0.25, 1 / 3, 0.4, 0.5, 0.6, 2 / 3, 0.75, 0.8, 0.9, 1.0,
        ]
    ]

    layout = qtile.current_group.layout
    node = layout.focused_node

    width = node.width
    difference = [abs(step - width) for step in width_steps]
    min_difference = min(difference)
    step_idx = difference.index(min_difference)

    next_step_idx = step_idx + direction
    if next_step_idx < 0 or next_step_idx >= len(width_steps):
        return

    want_width = width_steps[next_step_idx]

    percent = (want_width / screen_width) * 100

    logger.warn(f"Set width to {want_width}")
    send_notification("Set width", f"{percent:.0f}%", timeout=2000)

    layout.cmd_width(want_width)
    layout.focused_node.root.dump_structure()


def tune_height(qtile, direction):
    screen_height = qtile.current_screen.height

    for unused_area in (
        qtile.current_screen.top,
        qtile.current_screen.bottom,
    ):
        if unused_area:
            screen_height -= unused_area.size

    layout = qtile.current_group.layout
    node = layout.focused_node

    height_steps = [
        screen_height * step for step in [
            0.1, 0.2, 1 / 3, 0.5, 2 / 3, 0.8, 0.9,
        ]
    ]

    height = node.height

    difference = [abs(step - height) for step in height_steps]
    min_difference = min(difference)
    step_idx = difference.index(min_difference)

    next_step_idx = step_idx + direction
    if next_step_idx < 0 or next_step_idx >= len(height_steps):
        return

    want_height = height_steps[next_step_idx]

    logger.warn(f"Set height to {want_height}")
    layout.cmd_height(want_height)
    layout.focused_node.root.dump_structure()

# GROUPS


def next_oldest_focused_window() -> None:
    pass


groups = [
    Group(
        name="FF",
        matches=[
            Match(wm_class="rhythmbox"),
        ],
        # spawn=[
        #     'bash -c "pgrep firefox-bin || exec app firefox-bin MozillaFirefox"',
        #     'bash -c "pgrep rhythmbox || exec app rhythmbox Rhythmbox"',
        # ],
        persist=True,  # def
        init=True,     # def
    ),
    Group(
        name="CC",
        matches=[
        ],
    ),
    Group(
        name="KR",
        matches=[
            Match(wm_class="krusader"),
        ],
        spawn=['bash -c "pgrep krusader || exec app krusader Krusader"'],
    ),
    Group(
        name="TG",
        matches=[
            Match(wm_class="kmail"),
            Match(wm_class="TelegramDesktop"),
            Match(wm_class="discord"),
        ],
        spawn=['bash -c "pgrep Telegram || exec app telegram TelegramDesktop"'],
    ),
    Group(
        name="ZM",
        matches=[
            Match(wm_class="zoom"),
        ],
        spawn=['bash -c "pgrep zoom || exec app zoom Zoom"'],
    ),
    Group(
        name="BB",
        matches=[
            Match(wm_class="nxplayer.bin"),
        ],
    ),
    Group(
        name="EE",
        matches=[
            Match(wm_class="rustdesk"),
        ],
    ),
    Group(
        name="T00",
        persist=True,
        init=True,
    ),
]

# KEYMAP
EzKey.modifier_keys = {
    "A": "mod1",
    "S": "shift",
    "C": "control",
    "W": "mod4",
}


keymap = {
    # window nav
    "W-<Left>": lazy.layout.left(),
    "W-<Right>": lazy.layout.right(),
    "W-<Up>": lazy.layout.up(),
    "W-<Down>": lazy.layout.down(),

    "A-W-<Left>": lazy.layout.move_left(),
    "A-W-<Right>": lazy.layout.move_right(),
    "A-W-<Up>": lazy.layout.move_up(),
    "A-W-<Down>": lazy.layout.move_down(),

    "A-S-W-<Left>": lazy.layout.integrate_left(),
    "A-S-W-<Right>": lazy.layout.integrate_right(),
    "A-S-W-<Up>": lazy.layout.integrate_up(),
    "A-S-W-<Down>": lazy.layout.integrate_down(),

    "W-t": (lazy.function(new_tx), lazy.spawn(run_terminal)),
    "W-<Page_Up>": lazy.function(tx_prev),
    "W-<Page_Down>": lazy.function(tx_next),

    # 'C-A-y': lazy.layout.mode_horizontal(),
    # 'C-A-x': lazy.layout.mode_vertical(),

    "W-x": (lazy.layout.mode_vertical(), lazy.spawn(run_terminal)),
    "W-y": (lazy.layout.mode_horizontal(), lazy.spawn(run_terminal)),
    "W-S-x": (lazy.layout.mode_vertical(), lazy.spawn(run_terminal_tabbed)),
    "W-S-y": (lazy.layout.mode_horizontal(), lazy.spawn(run_terminal_tabbed)),

    # 'W-<Right>': lazy.layout.mode_horizontal(),
    # 'W-<Down>': lazy.layout.mode_vertical(),

    "W-f": lazy.window.toggle_floating(),
    "W-<Return>": lazy.window.toggle_fullscreen(),

    "A-<Tab>": lazy.function(next_oldest_focused_window()),
    # 'A-<Tab>': lazy.layout.recent(),
    # 'A-C-<Tab>': lazy.layout.next(),

    "W-<equal>": lazy.function(lambda qtile: tune_width(qtile, 1)),
    "W-<minus>": lazy.function(lambda qtile: tune_width(qtile, -1)),
    "W-0": lazy.function(lambda qtile: tune_height(qtile, 1)),
    "W-9": lazy.function(lambda qtile: tune_height(qtile, -1)),

    "W-n": lazy.layout.reset_size(),
    "W-g": lazy.spawn("qtile cmd-obj -o cmd -f togroup"),

    "W-q": lazy.window.kill(),
    # 'W-d': lazy.window.kill(),  # because <C-d> kills console... :)

    "W-S-d": lazy.spawn("bash -c 'sleep 0.5; redock'"),

    "W-S-r": lazy.reload_config(),
    "C-W-S-q": lazy.shutdown(),
    "C-S-A-<F4>": lazy.shutdown(),
    "<F12>": lazy.function(quaketoggle),

    "A-<F2>": lazy.run_extension(extension.J4DmenuDesktop(
        dmenu_command="fzfmenu",
        dmenu_prompt="run",
        dmenu_font="MProFont:size=13",
        selected_foreground="#00ff00",
        dmenu_lines=10,
        dmenu_ignorecase=True,
        selected_background=None,
        j4dmenu_command="/home/mocksoul/.local/bin/j4menu",
        j4dmenu_usage_log="/home/mocksoul/.local/share/qtile/appusage.stat",
        j4dmenu_display_binary=True,
        j4dmenu_generic=False,
    )),

    "A-S-<F2>": lazy.run_extension(extension.DmenuRun(
        dmenu_command="fzfmenu run",
        dmenu_prompt="run",
        dmenu_font="MProFont:size=13",  # or 9
        # background='#15181a',
        # foreground='#00ff00',
        # selected_background='#079822',
        selected_foreground="#00ff00",
        dmenu_lines=10,
        dmenu_ignorecase=True,
    )),

    "W-<F2>": lazy.spawn("/home/mocksoul/workspace/chrome-dmenu/chrome-dmenu.sh"),

    "C-<F1>": lazy.group["FF"].toscreen(),
    "C-<F2>": lazy.group["CC"].toscreen(),
    "C-<F3>": lazy.group["KR"].toscreen(),
    "C-<F4>": lazy.group["TG"].toscreen(),
    "C-<F5>": lazy.group["ZM"].toscreen(),
    "C-<F6>": lazy.group["BB"].toscreen(),
    "C-<F7>": lazy.group["EE"].toscreen(),
    "C-<F8>": lazy.group["T00"].toscreen(),

    "C-S-<F1>": lazy.window.togroup("FF", switch_group=True),
    "C-S-<F2>": lazy.window.togroup("CC", switch_group=True),
    "C-S-<F3>": lazy.window.togroup("KR", switch_group=True),
    "C-S-<F4>": lazy.window.togroup("TG", switch_group=True),
    "C-S-<F5>": lazy.window.togroup("ZM", switch_group=True),
    "C-S-<F6>": lazy.window.togroup("BB", switch_group=True),
    "C-S-<F7>": lazy.window.togroup("EE", switch_group=True),
    "C-S-<F8>": lazy.window.togroup("T00", switch_group=True),

    # media control
    "<XF86AudioPlay>": lazy.spawn("playerctl play-pause"),
    "<XF86AudioNext>": lazy.spawn("playerctl next"),
    "<XF86AudioPrev>": lazy.spawn("playerctl previous"),
    "<XF86AudioStop>": lazy.spawn("playerctl stop"),

    # "<XF86AudioMute>": lazy.spawn("amixer -D pulse sset Master toggle"),
    "<XF86AudioMute>": lazy.spawn("ao toggle"),
    # '<XF86AudioLowerVolume>': lazy.spawn('amixer -D pulse sset Master 1%-'),
    # '<XF86AudioRaiseVolume>': lazy.spawn('amixer -D pulse sset Master 1%+'),
    "<XF86AudioLowerVolume>": lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -1dB"),
    "<XF86AudioRaiseVolume>": lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +1dB"),

    "W-<F6>": lazy.spawn("ao dx1"),
    "W-<F7>": lazy.spawn("ao strix"),

    # 'W-l': lazy.spawn('xset dpms force off'),
    "W-l": lazy.spawn("i3lock --color 111111 --ignore-empty-password --show-failed-attempts"),

    # apps
    # 'C-A-v': lazy.spawn('qdbus org.kde.klipper /klipper org.kde.klipper.klipper.showKlipperPopupMenu'),
    "W-v": lazy.spawn("klipperdmenu"),
    "A-<Print>": (
        lazy.spawn("systemctl --user stop app-org.kde.spectacle.service"),
        lazy.spawn("killall spectacle"),
        lazy.spawn("spectacle"),
    ),
}

keys = []

for k, v in keymap.items():
    new_v = (v,) if not isinstance(v, list | tuple) else v
    keys.append(EzKey(k, *new_v))

keys.extend([
    KeyChord(
        [win], "o", [
            Key([], "equal", lazy.window.up_opacity()),
            Key([], "minus", lazy.window.down_opacity()),
        ],
        name="opacity",
    ),
    KeyChord(
        [win], "c", [
            Key([], "l", lazy.run_extension(extension.WindowList(
                all_groups=False,
                dmenu_font="MProFont:size=13",
                dmenu_ignorecase=True,
                dmenu_prompt="Window",
            ))),
        ],
        name="command",
    ),
])

# LAYOUTS
# set default dimensions big enough to fit all windows with already configured sizes
plasma_layout.Plasma.default_dimensions = (0, 0, 3840, 2160)  # type: ignore reportGeneralTypeIssues

layouts = [plasma_layout.Plasma(
    border_normal="#000000",            # unfocused
    # border_focus='#00e891',             # focused
    border_focus="#5fd75f",             # focused
    # border_normal_fixed='#006863',      # unfocused fixed-size
    border_normal_fixed="#000000",
    border_focus_fixed="#00e8dc",       # focused fixed-size
    border_width=3,                     # border width
    border_width_single=0,              # border with for single window
    margin=0,                           # layout margin
)]

# WIDGETS / SCREENS
class DellBattery(widget_battery._LinuxBattery):  # noqa: SLF001
    avg_state = None
    avg_count = 10
    avg = None

    bcfg_file = "/sys/class/firmware-attributes/dell-wmi-sysman/attributes/PrimaryBattChargeCfg/current_value"
    bcfg_stop_file = "/sys/class/firmware-attributes/dell-wmi-sysman/attributes/CustomChargeStop/current_value"

    def __init__(self, *args, **kwargs) -> None:
        self.avg = []
        super().__init__(*args, **kwargs)

    def multiplier(self: Self, retries: int = 2) -> float:
        try:
            with Path(self.bcfg_file).open() as fp:
                bcfg = fp.read().strip()
        except PermissionError:
            os.system(f"sudo chmod 644 {self.bcfg_file}")  # noqa: S605
            if retries > 0:
                return self.multiplier(retries - 1)
            raise

        if bcfg == "Custom":
            try:
                with Path(self.bcfg_stop_file).open() as fp:
                    stop_percent = int(fp.read().strip())
            except PermissionError:
                os.system(f"sudo chmod 644 {self.bcfg_stop_file}")  # noqa: S605
                if retries > 0:
                    return self.multiplier(retries - 1)
                raise

            return stop_percent / 100

        return 1.0

    def _get_param(self: Self, name: str) -> tuple[str, str]:
        ret = super()._get_param(name)
        if name == "energy_full_file":
            value = int(ret[0])
            value = int(value * self.multiplier())
            ret = (str(value), ret[1])
        return ret

    def update_status(self: Self) -> widget_battery.BatteryStatus:
        status = super().update_status()
        if status.state == widget_battery.BatteryState.UNKNOWN:
            status = widget_battery.BatteryStatus(
                state=widget_battery.BatteryState.FULL,
                percent=status.percent,
                power=status.power,
                time=0,
            )

        if status.time > (99 * 3600) or status.time < 0:
            status = widget_battery.BatteryStatus(
                state=status.state,
                percent=status.percent,
                power=status.power,
                time=99 * 3600,
            )

        status = self.get_average(status)

        return status

    def get_average(self: Self, status: widget_battery.BatteryStatus) -> widget_battery.BatteryStatus:
        if self.avg_state != status.state:
            self.avg_state = status.state
            self.avg[:] = []

        self.avg.append(status)

        while len(self.avg) > self.avg_count:
            self.avg.pop(0)

        return widget_battery.BatteryStatus(
            state=status.state,
            percent=status.percent,
            power=sum(s.power for s in self.avg) / len(self.avg),
            time=int(sum(s.time for s in self.avg) / len(self.avg)),
        )


class Battery(widget.Battery):
    @staticmethod
    def _load_battery(**config) -> DellBattery:
        return DellBattery(**config)


class DellThermalSensor(widget.ThermalSensor):
    def get_temp_sensors(self: typing.Self) -> dict:
        """
        Reads temperatures from sys-fs via psutil.
        Output will be read Fahrenheit if user has specified it to be.
        """

        if psutil is None:
            return {}

        temperature_list = {}
        temps = psutil.sensors_temperatures(fahrenheit=not self.metric)
        empty_index = 0
        for kernel_module in temps:
            for sensor in temps[kernel_module]:
                label = sensor.label
                if not label:
                    label = "{}-{}".format(
                        kernel_module if kernel_module else "UNKNOWN",
                        str(empty_index),
                    )
                    empty_index += 1
                temperature_list[label] = sensor.current

        temperature_list.update(self.analyze_nvme_temps(temps.get("nvme", [])))

        return temperature_list

    def analyze_nvme_temps(self: typing.Self, nvme_temps: list) -> dict:
        nvme_idx = -1

        nvme_temps_grouped = []

        # Group nvme temps
        # [sensor, sensor, sensor, sensor]
        #
        # to
        # [0: [sensor, sensor], 1: [sensor, sensor]]
        for sensor in nvme_temps:
            label = sensor.label
            if not label:
                continue

            if label == "Composite":
                nvme_idx += 1
                nvme_temps_grouped.append([])

            nvme_temps_grouped[nvme_idx].append(sensor)

        nvme_temps_result = {}

        for nvme_sensors in nvme_temps_grouped:
            looks_like_hikvision = False
            for sensor in nvme_sensors:
                hikvision_high_temp = 89.85
                if sensor.label == "Composite" and sensor.high == hikvision_high_temp:
                    looks_like_hikvision = True
                    break

            label = "nvme-hikvision" if looks_like_hikvision else "nvme-skhynix"

            for sensor in nvme_sensors:
                if sensor.label == "Composite":
                    nvme_temps_result[label] = sensor.current

        return nvme_temps_result

widget_defaults = {
    "font": "JetBrains Mono",
    "fontsize": 10,
    "padding": 10,
}
extension_defaults = widget_defaults.copy()


def normalize_window_title(s: str) -> str:
    if s.endswith("NVIM"):
        return "NV"

    if s.endswith(" - Chromium"):
        return "Chromium"

    if s.endswith("Firefox"):
        return "Firefox"

    return s

if pc == "dellbro":
    thermal_widgets = [
        DellThermalSensor(
            tag_sensor="Package id 0", threshold=90, update_interval=1, format="C={temp:.0f}{unit}",
        ),
        DellThermalSensor(
            tag_sensor="nvme-skhynix", threshold=70, update_interval=1, format="N1={temp:.0f}{unit}", padding=0,
        ),
        DellThermalSensor(
            tag_sensor="nvme-hikvision", threshold=60, update_interval=1, format="N2={temp:.0f}{unit}",
        ),
    ]
else:
    thermal_widgets = [
        widget.ThermalZone(
            format=" CPU={temp}C  ",
            format_crit=" CPU={temp}C  ",
            update_interval=0.5,
            high=60, crit=68, padding=0,
        ),
        widget.NvidiaSensors(format="RTX={temp}C  ", update_interval=0.5, padding=0),
    ]

if pc == "dellbro":
    battery_backlight_widgets = [
        widget.Sep(size_percent=50),
        widget.Backlight(
            format="bl={percent:2.0%}",
            backlight_name="intel_backlight",
            update_interval=1,
        ),
        widget.Sep(size_percent=50),
        Battery(
            format="bat {percent:5.1%} {char} {watt:4.1f}W ~{hour:2d}:{min:02d}",
            # charge_char="chr",
            # discharge_char="dis",
            # full_char="ful",
            # empty_char="emp",
            # unknown_char="unk",
            charge_char="^",
            discharge_char="v",
            full_char="=",
            empty_char="o",
            unknown_char="x",
            show_short_text=False,
            low_percentage=0.1,
            low_background="800000",
            low_foreground="FFFF00",
            update_interval=1,
        ),
    ]
else:
    battery_backlight_widgets = []

if pc == "dellbro":
    net_widgets = [
        widget.Sep(size_percent=50),
        widget.Net(interface="wln", use_bits=True, prefix="M", update_interval=1),
        widget.Net(interface="eno", use_bits=True, prefix="M", update_interval=1),
    ]
else:
    net_widgets = []

bar_items = [
    widget.Chord(
        chords_colors={
            "opacity": ("#0000ff", "#ffff00"),
            "command": ("#ffff00", "#000000"),
        },
        name_transform=lambda name: name.upper(),
    ),
    # widget.WindowCount(text_format="{num:02d}", show_zero=True),
    # widget.Sep(size_percent=50),
    widget.GroupBox(
        block_highlight_text_color="ffff00",
        highlight_method="block",
        urgen_alert_method="block",
        disable_drag=True,
        use_mouse_wheel=False,
        rounded=False,
        visible_groups=None,   # all
    ),
    widget.Sep(size_percent=50),
    widget.Prompt(),
    widget.WindowName(),
    widget.Spacer(),
    # widget.TaskList(
    # ),
    widget.Sep(size_percent=50),
    widget.Systray(background=None, padding=3),
    # widget.KeyboardLayout(
    # ),
    widget.Spacer(length=5),
    widget.Sep(size_percent=50),
    widget.CPU(format="{freq_current}GHz {load_percent:2.0f}%", update_interval=1),
    widget.Sep(size_percent=50),
    widget.Memory(measure_mem="G", format="{MemUsed:2.0f}{mm}"),
    widget.Sep(size_percent=50),
    *thermal_widgets,
    *net_widgets,
    widget.Sep(size_percent=50),
    widget.KeyboardKbdd(
        configured_keyboards=["us", "ru"],
        colours=["ffffff", "ffff00"],
        update_interval=0.1,
    ),
    widget.Sep(size_percent=50),
    widget.Wttr(
        location={"Moscow, Russia": "MSK"},
        format="%l: %C %f %h",
        units="M",
    ),
    *battery_backlight_widgets,
    widget.Sep(size_percent=50),
    widget.Clock(format="%a %d %b"),
    widget.Sep(size_percent=50),
    widget.Clock(format="%H:%M"),
    # widget.Sep(size_percent=50),
    # widget.QuickExit(
    #     default_text="[X]", countdown_format="[{}]",
    # ),
]

screens = [
    Screen(
        bottom=bar.Bar(
            bar_items, 20,
            background="#111111",
            border_width=[0, 10, 0, 10],  # Draw top and bottom borders
        ),
        wallpaper="/home/mocksoul/.local/share/wallpapers/ddusk4k.jpg",
    ),
]

# FLOAT MATCH


def zoom_match(cli: WindowBase) -> bool:
    cls = cli.get_wm_class()
    if not cls:
        return False

    mainwin = cli.name in ("zoom", "Zoom - Free Account", "Zoom Cloud Meetings")

    if mainwin:
        return True

    return False


floating_layout = layout.Floating(  # type: ignore reportPrivateImportUsage
    border_width=1,
    fullscreen_border_width=0,
    max_border_width=0,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,  # type: ignore reportPrivateImportUsage
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class="krunner"),
        Match(wm_class="solaar"),  # logitech mouse settings
        Match(wm_class="klipper"),
        Match(func=zoom_match),
        Match(wm_class="TelegramDesktop", title="Media viewer"),
        Match(wm_instance_class="AlacrittxFloating"),
        Match(wm_class="dmenu"),
        Match(wm_class="spectacle"),
    ],
)

# MISC
# Drag floating layouts.
mouse = [
    Drag([alt], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([alt], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([win], "Button1", lazy.window.bring_to_front()),
    Click([win], "Button3", lazy.window.toggle_minimize()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False

auto_fullscreen = True
focus_on_window_activation = "never"  # can be smart too
reconfigure_screens = True            # reconfigure on xrandr changes

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = False

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"


@hook.subscribe.startup
def startup() -> None:
    # for group in qtile.groups:


    to_add = []

    for window in qtile.windows_map.values():
        if window.group and window.group.name not in qtile.groups_map:
            to_add.append(window.group)

    to_add.sort(key=lambda x: x.name)

    for group in to_add:
        logger.info(f"adding group {group.name}")
        qtile.add_group(group.name)
        logger.info(group)


@hook.subscribe.startup_complete
def xstartup_complete() -> None:  # noqa: PLR0915,PLR0912,C901
    # restore window size if they was set


    logger.warn("-" * 100)

    structure = state._state.get("structure", {})  # noqa: SLF001

    logger.warn(pprint.pformat(qtile.groups))

    if 1:
        seen_wids = set()

        for group in qtile.groups:
            group_structure = structure.get(group.name, {})

            if group_structure and "childs" in group_structure:
                logger.warn(f"{group} WILL RESTORE GROUP STRUCTURE")

                layout = group.layout

                if not isinstance(layout, plasma_layout.Plasma):
                    continue

                resize_queue = []

                root = layout.root
                root.children[:] = []

                # remove all structure parts we have no windows for
                #
                # while jobs:
                #
                #     for child_part in childs:
                #         if 'wid' in child_part:
                #             if wid in qtile.windows_map:
                #

                jobs = [(root, group_structure["childs"])]

                if "size" in group_structure:
                    root.size = group_structure["size"]

                while jobs:
                    node, childs = jobs.pop(0)

                    for childinfo in childs:
                        if "wid" in childinfo:
                            wid = childinfo["wid"]
                            if wid in seen_wids:
                                continue
                            seen_wids.add(wid)
                            if wid in qtile.windows_map:
                                window = qtile.windows_map[wid]
                                logger.warn(f"recap window {window}")
                                newnode = PlasmaNode(window)
                                node.add_child(newnode)

                                if "size" in childinfo:
                                    resize_queue.append((newnode, childinfo["size"]))

                        elif "childs" in childinfo and childinfo["childs"]:
                            newnode = PlasmaNode()
                            node.add_child(newnode)
                            jobs.append((newnode, childinfo["childs"]))

                            if "size" in childinfo:
                                resize_queue.append((newnode, childinfo["size"]))

                for node, size in resize_queue:
                    logger.warn(f"resize node {node} min={node.min_size} {size} {node.x} {node.y}")
                    node.force_size(size)
                    layout.focus_node(node)
                    logger.warn(f"resize node {node} min={node.min_size} DONE {size} {node.x} {node.y}")

            if hasattr(group.layout, "finish"):
                group.layout.finish()

        for wid, window in qtile.windows_map.items():
            if window.__class__.__name__ in ("Internal", "Systray"):
                continue
            if window.floating:
                continue
            if wid not in seen_wids:
                logger.critical(f"EXTRA UNSEEN WID {wid} {window}")

                # if window.group:


                group = window.group
                group = qtile.groups_map[group.name]


                group.layout.add(window)


    state_focused = state._state.get("focused", None)  # noqa: SLF001

    logger.warn(f"ASK FOCUSED {state_focused}")
    if state_focused and isinstance(state_focused, int):
        window = qtile.windows_map.get(state_focused, None)
        logger.warn(f"FOCUS WIN {window}")
        if window:
            qtile.current_layout.focus(window)
            qtile.current_layout.refocus()

    state.unlock()


@hook.subscribe.client_new
def newclient(window):
    logger.warn(f"New window {window}")


@hook.subscribe.client_managed
def newmanaged(window):
    logger.warn(f"New window managed {window} {window.width} {window.height}")

    node = qtile.current_layout.root

    logger.warn(f"XXX CUR LAYOUT {node.width} {node.height} {node.orient}")

    for child in node.children:
        logger.warn(f"XXX CUR LAYOUT CHILD ORIENT {child.orient}")

    total_v, total_h = 0, 0

    for _ in node.children:
        total_v += 1

    total_h = 1

    for child in node.children:
        total_h = max(len(child.children), total_h)

    # if total_h == 0:

    logger.warn(f"CUR LAYOUT TOTAL V {total_v} H {total_h}")

    return

    res_1920p_h = 1920

    if window.width > res_1920p_h:
        node = qtile.current_layout.root.find_payload(window)
        ScreenRect(
            (node.width - 1920) / 2 + window.x,
            node.y,
            1920,
            node.height,
        )



@hook.subscribe.focus_change
def focus_changed() -> None:
    if not qtile.current_layout or not qtile.current_layout.focused:
        return

    curwid = qtile.current_layout.focused.wid
    logger.warn(f"SAVE FOCUS TO {curwid}")
    state.set_focus(qtile.current_layout.focused.wid)
    state.save()


logger.warn("XXX: CONFIG READED")
logger.warn(pprint.pformat(hook.subscriptions))
