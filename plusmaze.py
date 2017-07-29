import collections
import ok
import time
import wx

GateSetting = collections.namedtuple('Gate', 'epaddr cl op')

class PlusMaze(wx.Frame):
    settings = {'north': GateSetting(epaddr=0x03, cl=550, op=1200),
                'south': GateSetting(epaddr=0x00, cl=575, op=1200),
                'east': GateSetting(epaddr=0x01, cl=565, op=1200),
                'west': GateSetting(epaddr=0x02, cl=540, op=1200),
               }

    dosing_map = {'west':  4,
                  'north': 3,
                  'south': 2,
                  'east':  1,
                  'all': 0}

    rotation_map = {'center ccw': 5,
                    'center cw': 6}

    prox_map = {(0,2): 'center ccw',
                (2,3): 'center ccw',
                (3,1): 'center ccw',
                (1,0): 'center ccw',
                (0,1): 'center cw',
                (1,3): 'center cw',
                (3,2): 'center cw',
                (2,0): 'center cw'}
    
    def __init__(self, parent, title):
        wx.Frame.__init__(self, parent, title=title, size=(275,3*100),
                          style=wx.DEFAULT_FRAME_STYLE ^ wx.RESIZE_BORDER)

        # Initialize FPGA
        self.xem = ok.FrontPanel()
        if (self.xem.GetDeviceCount() == 0):
            print 'No Opal Kelly FPGAs detected'

        # Fixme: Always opens the first device
        self.serial = self.xem.GetDeviceListSerial(0)
        if (self.xem.NoError != self.xem.OpenBySerial(self.serial)):
            print 'Opal Kelly FPGA could not be opened.'

        self.xem.LoadDefaultPLLConfiguration()

        bitfile = 'toplevel.bit'
        if (self.xem.NoError != self.xem.ConfigureFPGA(bitfile)):
            print 'Failed to load {}'.format(bitfile)
        else:
            print 'Loaded {}'.format(bitfile)

        # Set up the GUI
        #------------------------------------------------------------
        gs = wx.GridSizer(3, 1)

        null_st = wx.StaticText(self, -1, '')
        header_font = wx.Font(pointSize=12,
                              family=wx.DEFAULT,
                              style=wx.SLANT,
                              weight=wx.BOLD)

        # Buttons for gate
        gate_st = wx.StaticText(self, -1, 'Gates:')
        gate_st.SetFont(header_font)
        
        gate_gs = wx.GridSizer(3, 2)
        gate_gs.Add(gate_st,
                    0, wx.ALIGN_CENTER_VERTICAL | wx.ALIGN_CENTER_HORIZONTAL)
        gate_gs.Add(null_st, 0, wx.EXPAND)
        self.gates = {'north': wx.ToggleButton(self,2),
                      'south': wx.ToggleButton(self,3),
                      'east': wx.ToggleButton(self,1),
                      'west': wx.ToggleButton(self,4)}
        for gate in ['west', 'north', 'south', 'east']:
            gate_gs.Add(self.gates[gate], 0, wx.EXPAND)

        gs.Add(gate_gs, 0, wx.EXPAND | wx.ALL, border=5)
        
        # Buttons for dosing
        dosing_st = wx.StaticText(self, -1, 'Dosing:')
        dosing_st.SetFont(header_font)

        dosing_gs = wx.GridSizer(3, 2)
        dosing_gs.Add(dosing_st,
                      0, wx.ALIGN_CENTER_VERTICAL | wx.ALIGN_CENTER_HORIZONTAL)

        doseall_btn = wx.Button(self, label="all")
        doseall_btn.Bind(wx.EVT_BUTTON, self.dose)
        dosing_gs.Add(doseall_btn, 0, wx.EXPAND)
        
        for gate in ['west', 'north', 'south', 'east']:
            dosegate_btn = wx.Button(self, label=gate)
            dosegate_btn.Bind(wx.EVT_BUTTON, self.dose)
            dosing_gs.Add(dosegate_btn, 0, wx.EXPAND)
            
        gs.Add(dosing_gs, 0, wx.EXPAND | wx.ALL, border=5)

        # Center platform rotation
        center_st = wx.StaticText(self, -1, "Rotation:")
        center_st.SetFont(header_font)

        center_gs = wx.GridSizer(2, 2)
        center_gs.Add(center_st,
                    0, wx.ALIGN_CENTER_VERTICAL | wx.ALIGN_CENTER_HORIZONTAL)
        center_gs.Add(null_st, 0, wx.EXPAND)

        for rotation in ['center cw', 'center ccw']:
            rot_btn = wx.Button(self, label=rotation)
            rot_btn.Bind(wx.EVT_BUTTON, self.rotate)
            center_gs.Add(rot_btn, 0, wx.EXPAND)
        
        gs.Add(center_gs, 0, wx.EXPAND | wx.ALL, border=5)
        
        self.SetSizer(gs)

        # Sample initial location of mouse (FIXME)
        self.xem.UpdateWireOuts()
        self.prox_prev = self.xem.GetWireOutValue(0x20)
        print "Initial proximity value: {}".format(self.prox_prev)
        
        self.timer = wx.Timer(self)
        self.timer.Start(250)
        self.Bind(wx.EVT_TIMER, self.update, self.timer)

        self.Show(True)

    def dose(self, event):
        # Get the label (e.g. "west") of the button that generated the event
        gate = event.EventObject.GetLabel()
        self.xem.ActivateTriggerIn(0x40,
                                   PlusMaze.dosing_map[gate]) # epAddr, bit
    def rotate(self, event):
        rot = event.EventObject.GetLabel()
        self.xem.ActivateTriggerIn(0x40,
                                   PlusMaze.rotation_map[rot]) # epAddr, bit

    def update(self, e):
        for gate in self.gates.keys():
            g = self.gates[gate]
            s = PlusMaze.settings[gate]
            if g.GetValue(): # Toggle closed
                v = s.cl
                g.SetLabel('{}: closed'.format(gate))
                g.SetBackgroundColour(wx.Colour(255,0,0))
            else:
                v = s.op
                g.SetLabel('{}: open'.format(gate))
                g.SetBackgroundColour(wx.Colour(0,255,0))
                
            v = s.cl if self.gates[gate].GetValue() else s.op
            self.xem.SetWireInValue(s.epaddr, v)
                
        self.xem.UpdateWireIns()

        # Get the proximity sensor reading
        self.xem.UpdateWireOuts()
        prox_curr = self.xem.GetWireOutValue(0x20)
        print prox_curr
        if (self.prox_prev != prox_curr):
            prox_path = (self.prox_prev, prox_curr)
            print "Position change detected!"
            rot = PlusMaze.prox_map[prox_path]
            self.xem.ActivateTriggerIn(0x40,
                                       PlusMaze.rotation_map[rot])
            #print "Need to rotate center as {}".format(PlusMaze.prox_map[prox_path])
        self.prox_prev = prox_curr


if (__name__ == "__main__"):
    app = wx.App(False)
    frame = PlusMaze(None, 'Plus maze controller')
    app.MainLoop()
