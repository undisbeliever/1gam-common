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


class LineReader:
    """
    A simple line reader that supports peeking at the next line.
    """
    def __init__(self, fp):
        self.fp = fp
        self.peek = fp.readline()

    def __iter__(self):
        return self

    def __next__(self):
        line = self.peek

        if line:
            self.peek = self.fp.readline()
            return line
        else:
            raise StopIteration



class MemoryMap:
    def __init__(self):
        self.addresses = dict()

    def load(self, filename):
        regex = re.compile(r'^([A-Za-z0-9_\-]+)\s+([A-Za-z0-9]{6})\s+[A-Z]{1,3}(?:\s+([A-Za-z0-9_\-]+)\s+([A-Za-z0-9]{6})\s)')

        with open(filename, 'r') as fp:
            for line in fp:
                m = regex.match(line)
                if m:
                    addr = int(m.group(2), 16) & 0x7FFFFF
                    self.addresses[addr] = m.group(1)

                    if m.group(3):
                        addr = int(m.group(4), 16) & 0x7FFFFF
                        self.addresses[addr] = m.group(3)

    def nameForAddress(self, addr):
        maddr = addr & 0x7FFFFF
        if maddr in self.addresses:
            return self.addresses[maddr]
        else:
            return None



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
        regex = re.compile(r'^([A-Za-z0-9]{6})\s+(\w+?)\s.+?V:\s*(\d+)\sH:\s*(\d+)')
        addr_regex = re.compile(r'^([A-Za-z0-9]{6})\s')

        reader = LineReader(fp)

        m = regex.match(reader.peek)
        if not m:
            raise ValueError("Not in a trace format")

        root = RoutineProfile(int(m.group(1), 16), None, -1)
        prevVTime = int(m.group(3))
        prevHTime = int(m.group(4))

        current = root

        for line in reader:
            m = regex.match(line)
            if m:
                # Calculate time between instructions.
                vTime = int(m.group(3))
                hTime = int(m.group(4))

                if vTime < prevVTime:
                    vTime += SNES_SCANLINES

                if prevVTime != vTime:
                    hTime += SNES_HTIME * (vTime - prevVTime)

                current.time += hTime - prevHTime

                prevVTime = int(m.group(3))
                prevHTime = int(m.group(4))


                # Determine if enter a routine
                inst = m.group(2).lower()
                instAddr = int(m.group(1), 16)

                if inst == 'jsr' or inst == 'jsl':
                    # Determine the location of the routine by address of next line
                    nm = addr_regex.match(reader.peek)
                    routineAddr = int(nm.group(1), 16)

                    p = current.get_or_make_call(instAddr, routineAddr)
                    p.count += 1
                    current = p

                # Determine if exit a routine
                if inst == 'rts' or inst == 'rtl':
                    if current.caller:
                        current = current.caller
                    else:
                        # Determine the location of the routine by address of next line
                        nm = addr_regex.match(reader.peek)
                        routineAddr = int(nm.group(1), 16)

                        current = RoutineProfile(routineAddr, None, -1)
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



def write_routine_times(fp, profile, memmap):
    totaltime = profile.totaltime

    fp.write('<h2>Routines:</h2>')
    fp.write('<table>')
    fp.write('<thead><th colspan="2">Routine</th><th>Count</th><th>Cycles</th><th>Percentage</th></thead>')
    fp.write('<tbody>')
    for r in profile.routines:
        fp.write("<tr>")

        aname = memmap.nameForAddress(r.address)
        if aname:
            fp.write("<td><tt>%06x</tt></td><td>%s</td>" % (
                r.address,
                aname
            ))
        elif r.address >= 0:
            fp.write("<td><tt>%06x</tt></td><td>&nbsp;</td>" % (
                r.address
            ))
        else:
            fp.write("<td><tt>NULL</tt></td><td>&nbsp;</td>")

        fp.write("<td>%d</td><td>%d</td><td>%f%%</td></tr>" % (
            r.count,
            r.time,
            r.time / totaltime * 100.0,
        ))
    fp.write('</tbody>')
    fp.write('</table>')



def write_profile_calls(fp, profile, memmap):

    def recurse(proutine, parent_totaltime):
        fp.write("<li>")

        aname = memmap.nameForAddress(proutine.address)
        if aname:
            fp.write("<tt>%06x</tt> %s" % (
                proutine.address,
                aname
            ))
        elif proutine.address >= 0:
            fp.write("<tt>%06x</tt>" % (
                proutine.address
            ))
        else:
            fp.write("<tt>NULL</tt>")

        fp.write(": Called at <tt>%06x</tt> %d times, %i cycles (%f%% parent, %f%% total)</li>" % (
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



def write_html(fp, profile, memmap):
    fp.write('<html><title>%s tracelog profile</title><body>' % profile.name)
    fp.write('<h1>%s</h1>' % profile.name)

    write_routine_times(fp, profile, memmap)
    write_profile_calls(fp, profile, memmap)

    fp.write('</body></html>')



def process_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('-m', '--memlog', type=str,
            help='Memlog file',
    )
    parser.add_argument('logfile',
            help='The SNES assembly trace file (`-` is stdin)',
    )
    parser.add_argument('htmlfile',
            help='The HTML output file (`-` is stdout)',
    )

    return parser.parse_args()


def main():
    args = process_args()

    memmap = MemoryMap()

    if args.memlog:
        memmap.load(args.memlog)

    if args.logfile == '-':
        profile = Profile('SNES')
        profile.read_trace(sys.stdin)
    else:
        name = os.path.splitext(os.path.basename(args.logfile))[0]
        with open(args.logfile, 'r') as fp:
            profile = Profile(name)
            profile.read_trace(fp)

    if args.htmlfile == '-':
        write_html(sys.stdout, profile, memmap)
    else:
        with open(args.htmlfile, 'w') as fp:
            write_html(fp, profile, memmap)


if __name__ == '__main__':
    main()


