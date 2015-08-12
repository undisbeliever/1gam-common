#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: set fenc=utf-8 ai ts=4 sw=4 sts=4 et:

"""
RoutineProfiles a bsnes assembly trace.
"""

# ::TODO read memlog file::
# ::TODO handle interrupts::
# ::TODO determine CPU utilisation by use of Screen__WaitFrame function::
# ::SHOULDO CPU usage per frame::

import re
import sys
import argparse
import os.path


SNES_SCANLINES = 262
SNES_HTIME     = 1374

class RoutineProfile:
    def __init__(self, addr, caller, callAddress):
        self.address = addr
        self.caller = caller
        self.callAddress = callAddress

        self.count = 0
        self.time = 0
        self.totaltime = -1
        self._calls = dict() # dict of tuple (callAddress, routineAddress) -> RoutineProfile

    def sorted_calls(self):
        return sorted(self._calls.values(), key=lambda x: x.totaltime, reverse=True)

    def calls(self):
        return self._calls.values()

    def get_or_make_call(self, callAddress, routineAddr):
        test = (callAddress, routineAddr)
        if test in self._calls:
            p = self._calls[test]
        else:
            p = RoutineProfile(routineAddr, self, callAddress)
            self._calls[test] = p

        return p

    def add_call(self, call):
        self._calls[(call.callAddress, call.address)] = call



class RoutineTotal:
    def __init__(self, addr):
        self.address = addr
        self.count = 0
        self.time = 0



class Profile:
    def __init__(self, name):
        self.name = name
        self.root = None


    def read_trace(self, fp):
        # ::TODO add bsnes-plus Frame Counter (optional)::
        regex = re.compile(r'^([A-Za-z0-9]{6})\s+(\w+?)\s[^\[]*(?:\[([A-Za-z0-9]{6})\])?\s.+?V:\s*(\d+)\sH:\s*(\d+)')

        line = fp.readline()
        m = regex.match(line)
        if not m:
            raise ValueError("Not in a trace format")

        root = RoutineProfile(int(m.group(1), 16), None, -1)
        prevVTime = int(m.group(4))
        prevHTime = int(m.group(5))

        current = root

        for line in fp:
            line = line.strip()
            m = regex.match(line)
            if m:
                # Calculate time between instructions.
                vTime = int(m.group(4))
                hTime = int(m.group(5))

                if vTime < prevVTime:
                    vTime += SNES_SCANLINES

                if prevVTime != vTime:
                    hTime += SNES_HTIME * (vTime - prevVTime)

                current.time += hTime - prevHTime

                prevVTime = int(m.group(4))
                prevHTime = int(m.group(5))


                # Determine if enter a routine
                inst = m.group(2).lower()
                instAddr = int(m.group(1), 16)

                if inst == 'jsr' or inst == 'jsl':
                    routineAddr = int(m.group(3), 16)

                    p = current.get_or_make_call(instAddr, routineAddr)
                    p.count += 1
                    current = p

                # Determine if exit a routine
                if inst == 'rts' or inst == 'rtl':
                    if current.caller:
                        current = current.caller
                    else:
                        # ::TODO get address after RTS/RTL ::
                        current = RoutineProfile(-1, None, -1)
                        root.caller = current
                        current.add_call(root)
                        root = current

        self.root = root
        self._calculate_total_time()
        self._generate_routines_list()


    def _calculate_total_time(self):
        def recurse(proutine):
            total = proutine.time
            for p in proutine.calls():
                total += recurse(p)

            proutine.totaltime = total

            return total

        self.totaltime = recurse(self.root)


    def _generate_routines_list(self):
        routines = dict()

        def recurse(proutine):
            addr = proutine.address
            if addr not in routines:
                routines[addr] = RoutineTotal(addr)

            routines[addr].count += proutine.count
            routines[addr].time += proutine.time

            for p in proutine.calls():
                recurse(p)

        recurse(self.root)
        self.routines = sorted(routines.values(), key=lambda x: x.time, reverse=True)



def write_routine_times(fp, profile):
    totaltime = profile.totaltime

    fp.write('<h2>Routines:</h2>')
    fp.write('<table>')
    fp.write('<thead><th>Routine</th><th>Count</th><th>Cycles</th><th>Percentage</th></thead>')
    fp.write('<tbody>')
    for r in profile.routines:
        fp.write("<tr><td><tt>%06x</tt></td><td>%d</td><td>%d</td><td>%f%%</td></tr>" % (
            r.address,
            r.count,
            r.time,
            r.time / totaltime * 100.0,
        ))
    fp.write('</tbody>')
    fp.write('</table>')



def write_profile_calls(fp, profile):

    def recurse(proutine, parent_totaltime):
        fp.write("<li><tt>%06x</tt>: Called at <tt>%06x</tt> %d times, %i cycles (%f%% parent, %f%% total)</li>" % (
                proutine.address,
                proutine.callAddress,
                proutine.count,
                proutine.totaltime,
                proutine.totaltime / parent_totaltime * 100.0,
                proutine.totaltime / profile.totaltime * 100.0,
        ))

        calls = proutine.sorted_calls()
        if calls:
            fp.write('<ul>')
            for p in calls:
                recurse(p, proutine.totaltime)
            fp.write('</ul>')

    fp.write('<h2>Profile:</h2>')
    fp.write('<ul>')

    recurse(profile.root, profile.totaltime)

    fp.write('</ul>')



def write_html(fp, profile):
    fp.write('<html><title>%s tracelog profile</title><body>' % profile.name)
    fp.write('<h1>%s</h1>' % profile.name)

    write_routine_times(fp, profile)
    write_profile_calls(fp, profile)

    fp.write('</body></html>')



def process_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('logfile',
            help='The SNES assembly trace file (`-` is stdin)',
    )
    parser.add_argument('htmlfile',
            help='The HTML output file (`-` is stdout)',
    )

    return parser.parse_args()


def main():
    args = process_args()

    if args.logfile == '-':
        profile = Profile('SNES')
        profile.read_trace(sys.stdin)
    else:
        name = os.path.splitext(os.path.basename(args.logfile))[0]
        with open(args.logfile, 'r') as fp:
            profile = Profile(name)
            profile.read_trace(fp)

    if args.htmlfile == '-':
        write_html(sys.stdout, profile)
    else:
        with open(args.htmlfile, 'w') as fp:
            write_html(fp, profile)


if __name__ == '__main__':
    main()


