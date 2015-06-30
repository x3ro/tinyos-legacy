#!/usr/bin/python
'''

   Copyright (c) 2005 Hewlett-Packard Company
   All rights reserved

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

      * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
         copyright notice, this list of conditions and the following
         disclaimer in the documentation and/or other materials provided
         with the distribution.
      * Neither the name of the <ORGANIZATION> nor the names of its
         contributors may be used to endorse or promote products derived
         from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

'''

import sys, os
import MySQLdb
import ConfigParser
import string, re
configFiles=['/etc/metro/servicedb.config', './servicedb.config' ]

from twisted.internet import protocol, reactor, error, defer, interfaces, address
from twisted.python import failure, components

from twisted.enterprise import adbapi 

from twisted.web import server, resource


verbose = 0

config=ConfigParser.ConfigParser()
config.read(configFiles)
dbhost = config.get('mysql', 'dbhost')
dbuser = config.get('mysql', 'dbuser')
dbpasswd = config.get('mysql', 'dbpasswd')
dbname = config.get('mysql', 'dbname')

http_port = int(config.get('http', 'port'))

title_string='<h1>Metro Patient, Device, and Service Database</h1><a href="/">TOP</a><p>'

#dbpool = adbapi.ConnectionPool("MySQLdb", 'metro', 'metro', 'password') 
dbpool = adbapi.ConnectionPool("MySQLdb", host=dbhost, db=dbname, user=dbuser, passwd=dbpasswd)

class ServiceRequest:
    def __init__(self, data, addr):
        self.data = data
        self.addr = addr
        lines = self.data.split('\r\n')
        self.requestline = lines[0]
        headers = lines[1:]
        self._headers = headers
        self.headers = {}
        for h in headers:
            if not re.search(':', h): continue 
            print h
            (k, v) = h.split(':', 1)
            self.headers[k.lower()] = v.strip()
        if not self.headers.has_key('status'):
            self.headers['status'] = '<unknown>'
        if not self.headers.has_key('expires'):
            self.headers['expires'] = 3600
        if not self.headers.has_key('name'):
            self.headers['name'] = '<noname>'
        if verbose: print self.headers
        requestinfo = lines[0].split(' ')
        self.method = requestinfo[0]
        if self.method == 'REGISTER':
            self.table = requestinfo[1]
        elif self.method == 'QUERY':
            self.table = requestinfo[1]
        return
    def nullCallback(self, l):
        return
    def dbCallback(self, l):
        response = string.join([ did for (did,) in l], "\r\n")
        print 'dbCallback response=', response
        port.write(response, self.addr)
        return
    def runRegisterDeviceRequest(self):
        deviceid = self.headers['did']
        ipaddr = self.headers['ip']
        dtype = self.headers['type']
        expires = self.headers['expires']
        query = ("replace into device (deviceid, ipaddr, dtype, expires) values ('%s', '%s', '%s', date_add(NOW(), interval %d second))"
                 % (deviceid, ipaddr, dtype, expires))
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(self.dbCallback)
    def runRegisterServiceAttributesRequest(self):
        deviceid = self.headers['did']
        sname = self.headers['svn']
        port = self.headers['svp']
        stype = self.headers['svt']
        status = self.headers['status']
        expires = self.headers['expires']

        begin_query = 'update service set '
        end_query = " where deviceid='%s' and port=%d'" % (deviceid, port)
        updates = []
        for k, v in [('sname', sname), ('stype', stype), ('status', status)]:
            if v:
                updates.append( "%s='%s'" % (k, v))
        query = begin_query + string.join(updates, ', ') + end_query
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(self.dbCallback)
    def runRegisterServiceRequest(self):
        print 'runRegisterServiceRequest'
        deviceid = self.headers['did']
        sname = self.headers['svn']
        stype = self.headers['svt']
        port = self.headers['svp']
        query = ("replace into service (sname, stype, deviceid, port, expires) values ('%s', '%s', '%s', '%s', date_add(NOW(), interval %d second))"
                 % (sname, stype, deviceid, port, 3600))
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(self.dbCallback)
    def runQueryPatientRequest(self):
        deviceid = self.headers['did']
        (ipaddr, udpport) = self.addr
        if self.headers.has_key('dtype'):
            dtype = self.headers['dtype']
        else:
            dtype = '<unknown>'
        def updateDevice():
            query = "replace into device (deviceid, dtype, ipaddr) values ('%s', '%s', '%s')" % (deviceid, dtype, ipaddr)
            if verbose: print 'updateDevice: ', query
            defer = dbpool.runQuery(query)
            defer.addCallback(self.nullCallback)
        def queryCallback(l):
            if (len(l) > 0):
                (pid, name) = l[0]
                response = '200 OK\r\n' + 'PID: ' + pid + '\r\nName: ' + name + '\r\n'
                if verbose: print 'queryCallback response=', response
                port.write(response, self.addr)
            updateDevice()
            return
        query = ("select patient.patientid, name from patient, patientdevice where patientdevice.deviceid='%s' and patientdevice.patientid = patient.patientid"
                 % (deviceid, ))
        if verbose: print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)

    def runQueryServiceRequest(self):
        result_columns = ('sname', 'stype', 'ipaddr', 'port', 'service.status')
        result_headers = ('SVN', 'SVT', 'IP', 'Port', 'Status')
        def queryServiceCallback(l):
            for res in l:
                response = string.join([ '%s: %s\r\n' % (hn, cv) for (hn, cv) in zip(result_headers, res) ], '')
                print 'queryServiceCallback response=', response
                port.write('200 OK\r\n' + response, self.addr)
            return
        query = 'select %s from service, device where service.deviceid=device.deviceid ' % string.join(result_columns, ',')
        for (hn, cn) in (('svn', 'sname'), ('svt', 'stype'), ('did', 'deviceid'), ('pid', 'patientid')):
            if self.headers.has_key(hn) and self.headers[hn] != '*':
                query = query + ('and %s = "%s" ' % (cn, self.headers[hn]))
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryServiceCallback)

    def runRequest(self):
        if self.method == 'REGISTER':
            if self.table == 'device':
                self.runRegisterDeviceRequest()
            elif self.table == 'service':
                self.runRegisterServiceRequest()
            elif self.table == 'attrs':
                self.runRegisterServiceAttributesRequest()
        elif self.method == 'QUERY':
            if self.table == 'patient':
                self.runQueryPatientRequest()
            elif self.table == 'service':
                self.runQueryServiceRequest()
        return

class ServiceDBServer(protocol.DatagramProtocol):
    def datagramReceived(self, data, addr):
        ##print data, addr
        request = ServiceRequest(data, addr)
        request.runRequest()
        
print dbpool

def printResult(l):
    for r in l:
        print r

def renderDeviceID(deviceid):
    return '<a href="/devices/%s">%s</a>' % (deviceid, deviceid)
def renderPatientID(patientid):
    return '<a href="/patients/%s">%s</a>' % (patientid, patientid)
def renderSType(stype):
    return '<a href="/services/%s">%s</a>' % (stype, stype)

class Simple(resource.Resource):
    def getChild(self, name, request):
        if name == '':
            return self
        else:
            return resource.Resource.getChild(self, name, request)
    def render_GET(self, request):
        def patientsCallback(l):
            request.write('<a href="/patients"><h2>Patients</h2></a><p></html>')
            request.write('<ul>')
            for (name, pid, did, dtype) in l:
                request.write('<li> %s: %s' % (renderPatientID(pid), name))
                if did:
                    request.write(' on %s device %s' % (dtype, renderDeviceID(did)))
            request.write('</ul>')
            request.write('</body>')
            request.write('</html>')
            request.finish()

        def servicesCallback(l):
            request.write('<a href="/services"><h2>Services</h2></a><p>')
            request.write('<ul>')
            for (did, sname, stype, ipaddr, port) in l:
                request.write('<li> %s on %s (%s:%s:%s)' % (renderSType(sname), renderDeviceID(did), stype, ipaddr, port))
            request.write('</ul>')
            query = "select patient.name, patient.patientid, patientdevice.deviceid, dtype from patient left join patientdevice on patientdevice.patientid = patient.patientid left join device on patientdevice.deviceid = device.deviceid"
            print query
            defer = dbpool.runQuery(query)
            defer.addCallback(patientsCallback)

        def devicesCallback(l):
            request.write('<html>')
            request.write('<head><META HTTP-EQUIV=Refresh CONTENT=\"10; URL=/\">')
            request.write('<body>')
            request.write(title_string)
            request.write('<a href="/devices"><h2>Devices</h2></a><p></html>')
            request.write('<ul>')
            for (did, dtype, ipaddr) in l:
                request.write('<li> %s: (%s) at %s' % (renderDeviceID(did), dtype, ipaddr))
            request.write('</ul>')
            query = ("select device.deviceid, sname, stype, ipaddr, port from service, device where service.deviceid = device.deviceid")
            print query
            defer = dbpool.runQuery(query)
            defer.addCallback(servicesCallback)

        query = ("select deviceid, dtype, ipaddr from device")
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(devicesCallback)
        return server.NOT_DONE_YET

class DeviceResource(resource.Resource):
    def render_GET(self, request):
        def queryCallback(l):
            print l
            request.write("<html>")
            request.write(title_string)
            request.write("Device %s<br>" % (self.name))
            p = string.join([ 'DID: %s Type: %s Address: %s <br>' % (renderDeviceID(did), dtype, ipaddr)
                              for (did, dtype, ipaddr) in l], "\r\n")
            request.write(p)
            request.write('</html>\r\n')
            request.finish()
        query = ("select deviceid, dtype, ipaddr from device where deviceid='%s'" % self.name)
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)
        return server.NOT_DONE_YET

class Devices(resource.Resource):
    def getChild(self, name, request):
        if name == '':
            return self
        else:
            dr = DeviceResource()
            dr.name = name
            return dr
    def render_GET(self, request):
        def queryCallback(l):
            print l
            request.write("<html><head><META HTTP-EQUIV=Refresh CONTENT=\"10; URL=/devices/\"></head>")
            request.write(title_string)
            request.write("<body>Devices:<br>")
            for (did, dtype, ipaddr) in l:
                request.write( 'DID: <a %(rdid)s Type: %(dtype)s Address: %(ipaddr)s <br>'
                               % { 'rdid': renderDeviceID(did), 'dtype': dtype, 'ipaddr': ipaddr} )
            request.write('\r\n</html>\r\n')
            request.finish()
        query = ("select deviceid, dtype, ipaddr from device")
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)
        return server.NOT_DONE_YET

class PatientResource(resource.Resource):
    def render_GET(self, request):
        def queryDevicesCallback(l):
            request.write('<ul>')
            for (did,) in l:
                request.write('<li> %(rdid)</li>' % { 'rdid': renderDeviceID(did) })
            request.write('</ul>')
            request.write('</html>')
            request.finish()
        def queryCallback(l):
            p = string.join([ 
                              ], "<br>")
            request.write( "<html>")
            request.write(title_string)
            request.write("Patients:<p>")
            request.write("<ul>")
            print l
            for (pid,pname,did) in l:
                request.write('<li>PID: %(rpid)s Name: %(pname)s'
                              % { 'rpid': renderPatientID(pid), 'pname': pname })
                if did:
                    request.write(' Device: %s' % renderDeviceID(did))
            request.write("</ul>")
            request.write("""<form method="post" action="/patients/newdevice">
                          </form>
            """)
            if 1:
                request.write('</html>')
                request.finish()
            else:
                query = ("select deviceid from patient, patientdevice where patient.patientid='%s' and patientdevice.patientid = patient.patientid" % self.patientid)
                print query
                defer = dbpool.runQuery(query)
                defer.addCallback(queryDevicesCallback)
        ##query = ("select patientid, name from patient where patientid='%s'" % self.patientid)
        query = ("select patient.patientid, name, patientdevice.deviceid from patient left join patientdevice on patientdevice.patientid = patient.patientid where patient.patientid='%s'" % self.patientid)
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)
        return server.NOT_DONE_YET

class NewPatientResource(resource.Resource):
    def render_GET(self, request):
        def nprCallback(l):
            print 'nprCallback', l
            request.write("<html>")
            request.write(title_string)
            request.write("""<h1>New Patient</h1>
                          <form method="post" action="/patients/add">
                          <table>
                          <tr><td>Patient Name<td><input type="text" name="pname"></input></tr>
                          <tr><td>Patient ID<td><input type="text" name="pid"></input></tr>
                          </table>
                          <input type="submit" name="Add">
                          </form>
                          """)
            request.finish()
        query = 'select deviceid from device'
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(nprCallback)
        return server.NOT_DONE_YET
    def render_POST(self, request):
        pname = request.args['pname'][0]
        pid = request.args['pid'][0]
        print 'args=', request.args
        print 'request.received_headers', request.received_headers
        def nprPostCallback(l):
            request.write('<html>Patient <a href="/patients/%s">%s</a> added.</html>' % (pid, pname))
            request.finish()
        query = "insert into patient (patientid, name) values ('%s', '%s')" % (pid, pname)
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(nprPostCallback)
        return server.NOT_DONE_YET
        

class Patients(Simple):
    def getChild(self, name, request):
        if name == 'add':
            return NewPatientResource()
        elif name == '':
            return self
        else:
            pr = PatientResource()
            pr.patientid = name
            return pr
    def render_GET(self, request):
        def queryCallback(l):
            p = string.join([ 'PID: ' + renderPatientID(pid) + ' Name: ' + name for (pid, name) in l], "<br>")
            request.write( "<html>")
            request.write(title_string)
            request.write("Patients:<br>")
            request.write(p)
            request.write('<p><a href="/patients/add">Add patient</a>')
            request.write("</html>")
            request.finish()
        query = ("select patientid, name from patient")
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)
        return server.NOT_DONE_YET

class ServiceResource(resource.Resource):
    def render_GET(self, request):
        def queryCallback(l):
            request.write("<html>")
            request.write(title_string)
            request.write("Service %s<br>\r\n" % self.sname)
            for (sname, stype, deviceid, ipaddr, port, status) in l:
                request.write('Service %s on device %s (%s:%s:%s) status is %s<br>\r\n'
                              % (sname, deviceid, stype, ipaddr, port, status) )
            request.write("</html>")
            request.finish()
        query = ("select sname, stype, service.deviceid, ipaddr, port, status from service, device where service.deviceid = device.deviceid and sname='%s'" % self.sname)
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)
        return server.NOT_DONE_YET

class Services(Simple):
    def getChild(self, name, request):
        sr = ServiceResource()
        sr.sname = name
        return sr
    def render_GET(self, request):
        def queryCallback(l):
            request.write("<html>")
            request.write(title_string)
            request.write("Services:<br>")
            for (sname, stype, deviceid, ipaddr, port, status) in l:
                dict = { 'sname': sname, 'deviceid': deviceid, 'stype': stype,
                         'ipaddr': ipaddr, 'port': port, 'status': status }
                request.write('Service <a href="/services/%(sname)s">%(sname)s</a>' % dict)
                request.write('\t on device <a href="/devices/%(deviceid)s" (%(stype)s:%(ipaddr)s:%(port)s)' % dict)
                request.write(' status is %(status)s<br>\r\n' % dict)
            request.write("</html>")
            request.finish()
        query = ("select sname, stype, service.deviceid, ipaddr, port, status from service, device where service.deviceid = device.deviceid")
        print query
        defer = dbpool.runQuery(query)
        defer.addCallback(queryCallback)
        return server.NOT_DONE_YET

root=Simple()
root.putChild('devices', Devices())
root.putChild('patients', Patients())
root.putChild('services', Services())
site = server.Site(root)
reactor.listenTCP(http_port, site)

webserver = ServiceDBServer()
port = reactor.listenUDP(4111, webserver)

reactor.run()
