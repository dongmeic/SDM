import os

import numpy as np
import pandas as pd


class ModelMatrixConstructor:
    def __init__(self, data_dir):
        self.DATA_DIR = data_dir
        self.SQUARE = [
            'lon', 'lat', 'etopo1', 'age', 'density', 'JanTmin', 'MarTmin', 'maxT',
            'TMarAug', 'summerTmean', 'AugTmean','PMarAug','TMarAug','Tmin', 'summerP2',
            'summerP1', 'OctTmin','Tvar', 'TOctSep', 'summerP0', 'Pmean', 'POctSep', 'wd',
            'PcumOctSep', 'PPT', 'cwd']
        self.CUBE = ['ddAugJul','ddAugJun','Tmean','TMarAug','fallTmean','TOctSep','vpd','AugMaxT','AugTmax']
        self.INTERACTIONS = ['age:density', 'age:summerTmean', 'age:summerP0', 'age:ddAugJul', 'density:JanTmin', 
                             'density:Tmean', 'density:OptTsum', 'density:wd', 'density:mi', 'density:ddAugJul']
        # self.INTERACTIONS = [
        #     'age:density', 'age:TMarAug', 'age:summerTmean', 'age:AugTmean', 'age:AugTmax', 
        #     'age:PMarAug', 'age:summerP0', 'age:Tvar', 'age:summerP1', 'age:summerP2', 
        #     'age:Pmean', 'age:POctSep', 'age:PcumOctSep', 'age:PPT', 'age:maxAugT', 
        #     'age:OptTsum', 'age:AugMaxT', 'age:maxT', 'age:drop5', 'age:max.drop', 
        #     'age:ddAugJul', 'age:ddAugJun', 'age:cv.gsp', 'age:wd', 'age:vpd', 'age:mi', 
        #     'age:cwd', 'age:pt.coef', 'density:JanTmin', 'density:MarTmin', 'density:TMarAug', 
        #     'density:summerTmean', 'density:AugTmean', 'density:AugTmax', 'density:PMarAug', 
        #     'density:summerP0', 'density:OctTmin', 'density:fallTmean', 'density:Tmin', 
        #     'density:Tmean', 'density:TOctSep', 'density:summerP1', 'density:summerP2', 
        #     'density:Pmean', 'density:POctSep', 'density:PcumOctSep', 'density:PPT', 
        #     'density:maxAugT', 'density:OptTsum', 'density:AugMaxT', 'density:maxT', 
        #     'density:Acs', 'density:drop0', 'density:drop5', 'density:max.drop', 'density:ddAugJul',
        #     'density:ddAugJun', 'density:OctMin', 'density:JanMin', 'density:MarMin', 'density:winterMin', 
        #     'density:minT', 'density:cv.gsp', 'density:wd', 'density:vpd', 'density:mi', 'density:cwd', 
        #     'density:pt.coef', 'JanTmin:MarTmin', 'JanTmin:TMarAug', 'JanTmin:summerTmean', 
        #     'JanTmin:AugTmean', 'JanTmin:AugTmax', 'JanTmin:summerP0', 'JanTmin:OctTmin', 'JanTmin:fallTmean', 
        #     'JanTmin:Tmin', 'JanTmin:Tmean', 'JanTmin:Tvar', 'JanTmin:TOctSep', 'JanTmin:summerP1', 
        #     'JanTmin:summerP2', 'JanTmin:Pmean', 'JanTmin:POctSep', 'JanTmin:PcumOctSep', 'JanTmin:PPT', 
        #     'JanTmin:maxAugT', 'JanTmin:Acs', 'JanTmin:drop0', 'JanTmin:drop5', 'JanTmin:max.drop', 
        #     'JanTmin:OctMin', 'JanTmin:JanMin', 'JanTmin:MarMin', 'JanTmin:winterMin', 'JanTmin:minT', 
        #     'JanTmin:wd', 'JanTmin:cwd', 'JanTmin:pt.coef', 'MarTmin:TMarAug', 'MarTmin:summerTmean', 
        #     'MarTmin:AugTmean', 'MarTmin:AugTmax', 'MarTmin:summerP0', 'MarTmin:OctTmin', 'MarTmin:fallTmean', 
        #     'MarTmin:Tmin', 'MarTmin:Tmean', 'MarTmin:Tvar', 'MarTmin:TOctSep', 'MarTmin:summerP1', 
        #     'MarTmin:summerP2', 'MarTmin:Pmean', 'MarTmin:POctSep', 'MarTmin:PcumOctSep', 'MarTmin:PPT', 
        #     'MarTmin:maxAugT', 'MarTmin:AugMaxT', 'MarTmin:maxT', 'MarTmin:Acs', 'MarTmin:drop0', 
        #     'MarTmin:drop5', 'MarTmin:max.drop', 'MarTmin:OctMin', 'MarTmin:JanMin', 'MarTmin:MarMin', 
        #     'MarTmin:winterMin', 'MarTmin:minT', 'MarTmin:vpd', 'MarTmin:cwd', 'MarTmin:pt.coef', 
        #     'TMarAug:summerTmean', 'TMarAug:AugTmean', 'TMarAug:AugTmax', 'TMarAug:PMarAug', 
        #     'TMarAug:summerP0', 'TMarAug:OctTmin', 'TMarAug:fallTmean', 'TMarAug:Tmin', 'TMarAug:Tmean', 
        #     'TMarAug:Tvar', 'TMarAug:TOctSep', 'TMarAug:summerP1', 'TMarAug:summerP2', 'TMarAug:Pmean',
        #     'TMarAug:POctSep', 'TMarAug:PcumOctSep', 'TMarAug:PPT', 'TMarAug:maxAugT', 'TMarAug:OptTsum', 
        #     'TMarAug:AugMaxT', 'TMarAug:maxT', 'TMarAug:Acs', 'TMarAug:drop5', 'TMarAug:max.drop', 
        #     'TMarAug:ddAugJul', 'TMarAug:ddAugJun', 'TMarAug:OctMin', 'TMarAug:JanMin', 'TMarAug:MarMin', 
        #     'TMarAug:winterMin', 'TMarAug:minT', 'TMarAug:wd', 'TMarAug:vpd', 'TMarAug:mi', 'TMarAug:cwd', 
        #     'TMarAug:pt.coef', 'summerTmean:AugTmean', 'summerTmean:AugTmax', 'summerTmean:PMarAug', 
        #     'summerTmean:summerP0', 'summerTmean:OctTmin', 'summerTmean:fallTmean', 'summerTmean:Tmin', 
        #     'summerTmean:Tmean', 'summerTmean:TOctSep', 'summerTmean:summerP1', 'summerTmean:summerP2', 
        #     'summerTmean:Pmean', 'summerTmean:POctSep', 'summerTmean:PcumOctSep', 'summerTmean:PPT', 
        #     'summerTmean:maxAugT', 'summerTmean:OptTsum', 'summerTmean:AugMaxT', 'summerTmean:maxT', 
        #     'summerTmean:ddAugJul', 'summerTmean:ddAugJun', 'summerTmean:OctMin', 'summerTmean:JanMin', 
        #     'summerTmean:MarMin', 'summerTmean:winterMin', 'summerTmean:minT', 'summerTmean:cv.gsp', 
        #     'summerTmean:wd', 'summerTmean:vpd', 'summerTmean:mi', 'summerTmean:cwd', 'summerTmean:pt.coef', 
        #     'AugTmean:AugTmax', 'AugTmean:PMarAug', 'AugTmean:summerP0', 'AugTmean:OctTmin', 'AugTmean:fallTmean', 
        #     'AugTmean:Tmin', 'AugTmean:Tmean', 'AugTmean:TOctSep', 'AugTmean:summerP1', 'AugTmean:summerP2', 
        #     'AugTmean:Pmean', 'AugTmean:POctSep', 'AugTmean:PcumOctSep', 'AugTmean:PPT', 'AugTmean:maxAugT', 
        #     'AugTmean:OptTsum', 'AugTmean:AugMaxT', 'AugTmean:maxT', 'AugTmean:Acs', 'AugTmean:max.drop', 
        #     'AugTmean:ddAugJul', 'AugTmean:ddAugJun', 'AugTmean:OctMin', 'AugTmean:JanMin', 'AugTmean:MarMin', 
        #     'AugTmean:winterMin', 'AugTmean:minT', 'AugTmean:cv.gsp', 'AugTmean:wd', 'AugTmean:vpd', 
        #     'AugTmean:mi', 'AugTmean:cwd', 'AugTmean:pt.coef', 'AugTmax:PMarAug', 'AugTmax:summerP0', 
        #     'AugTmax:OctTmin', 'AugTmax:fallTmean', 'AugTmax:Tmin', 'AugTmax:Tmean', 'AugTmax:TOctSep', 
        #     'AugTmax:summerP1', 'AugTmax:summerP2', 'AugTmax:Pmean', 'AugTmax:POctSep', 'AugTmax:PcumOctSep', 
        #     'AugTmax:PPT', 'AugTmax:maxAugT', 'AugTmax:OptTsum', 'AugTmax:AugMaxT', 'AugTmax:maxT', 'AugTmax:Acs', 
        #     'AugTmax:drop0', 'AugTmax:max.drop', 'AugTmax:ddAugJul', 'AugTmax:ddAugJun', 'AugTmax:OctMin', 
        #     'AugTmax:JanMin', 'AugTmax:MarMin', 'AugTmax:winterMin', 'AugTmax:minT', 'AugTmax:cv.gsp', 
        #     'AugTmax:wd', 'AugTmax:vpd', 'AugTmax:mi', 'AugTmax:cwd', 'AugTmax:pt.coef', 'PMarAug:summerP0', 
        #     'PMarAug:fallTmean', 'PMarAug:Tmean', 'PMarAug:Tvar', 'PMarAug:TOctSep', 'PMarAug:summerP1', 
        #     'PMarAug:summerP2', 'PMarAug:Pmean', 'PMarAug:POctSep', 'PMarAug:PcumOctSep', 'PMarAug:PPT', 
        #     'PMarAug:maxAugT', 'PMarAug:OptTsum', 'PMarAug:AugMaxT', 'PMarAug:maxT', 'PMarAug:drop0', 'PMarAug:drop5', 
        #     'PMarAug:ddAugJul', 'PMarAug:ddAugJun', 'PMarAug:wd', 'PMarAug:vpd', 'PMarAug:mi', 'PMarAug:cwd', 
        #     'PMarAug:pt.coef', 'summerP0:OctTmin', 'summerP0:fallTmean', 'summerP0:Tmin', 'summerP0:Tmean', 
        #     'summerP0:TOctSep', 'summerP0:summerP1', 'summerP0:summerP2', 'summerP0:Pmean', 'summerP0:POctSep', 
        #     'summerP0:PcumOctSep', 'summerP0:PPT', 'summerP0:maxAugT', 'summerP0:AugMaxT', 'summerP0:maxT', 
        #     'summerP0:max.drop', 'summerP0:OctMin', 'summerP0:JanMin', 'summerP0:MarMin', 'summerP0:winterMin', 
        #     'summerP0:minT', 'summerP0:wd', 'summerP0:mi', 'summerP0:cwd', 'summerP0:pt.coef', 'OctTmin:fallTmean', 
        #     'OctTmin:Tmin', 'OctTmin:Tmean', 'OctTmin:Tvar', 'OctTmin:TOctSep', 'OctTmin:summerP1', 'OctTmin:summerP2', 
        #     'OctTmin:Pmean', 'OctTmin:POctSep', 'OctTmin:PcumOctSep', 'OctTmin:PPT', 'OctTmin:maxAugT', 'OctTmin:AugMaxT', 
        #     'OctTmin:maxT', 'OctTmin:Acs', 'OctTmin:max.drop', 'OctTmin:OctMin', 'OctTmin:JanMin', 'OctTmin:MarMin', 
        #     'OctTmin:winterMin', 'OctTmin:minT', 'OctTmin:vpd', 'OctTmin:cwd', 'OctTmin:pt.coef', 'fallTmean:Tmin', 
        #     'fallTmean:Tmean', 'fallTmean:Tvar', 'fallTmean:TOctSep', 'fallTmean:summerP1', 'fallTmean:summerP2',
        #     'fallTmean:maxAugT', 'fallTmean:OptTsum', 'fallTmean:AugMaxT', 'fallTmean:maxT', 'fallTmean:Acs', 
        #     'fallTmean:drop0', 'fallTmean:drop5', 'fallTmean:max.drop', 'fallTmean:ddAugJul', 'fallTmean:ddAugJun', 
        #     'fallTmean:OctMin', 'fallTmean:JanMin', 'fallTmean:MarMin', 'fallTmean:winterMin', 'fallTmean:minT', 
        #     'fallTmean:wd', 'fallTmean:vpd', 'fallTmean:mi', 'fallTmean:cwd', 'fallTmean:pt.coef', 'Tmin:Tmean', 
        #     'Tmin:Tvar', 'Tmin:TOctSep', 'Tmin:summerP1', 'Tmin:summerP2', 'Tmin:Pmean', 'Tmin:POctSep', 
        #     'Tmin:PcumOctSep', 'Tmin:PPT', 'Tmin:maxAugT', 'Tmin:AugMaxT', 'Tmin:Acs', 'Tmin:drop0', 'Tmin:drop5', 
        #    'Tmin:max.drop', 'Tmin:OctMin', 'Tmin:JanMin', 'Tmin:MarMin', 'Tmin:winterMin', 'Tmin:minT', 'Tmin:wd', 
        #    'Tmin:cwd', 'Tmin:pt.coef', 'Tmean:Tvar', 'Tmean:TOctSep', 'Tmean:summerP1', 'Tmean:summerP2', 
        #    'Tmean:maxAugT', 'Tmean:OptTsum', 'Tmean:AugMaxT', 'Tmean:maxT', 'Tmean:Acs', 'Tmean:drop0', 'Tmean:drop5',
        #    'Tmean:max.drop', 'Tmean:ddAugJul', 'Tmean:ddAugJun', 'Tmean:OctMin', 'Tmean:JanMin', 'Tmean:MarMin', 
        #    'Tmean:winterMin', 'Tmean:minT', 'Tmean:wd', 'Tmean:vpd', 'Tmean:mi', 'Tmean:cwd', 'Tmean:pt.coef', 
        #    'Tvar:TOctSep', 'Tvar:Pmean', 'Tvar:POctSep', 'Tvar:PcumOctSep', 'Tvar:PPT', 'Tvar:maxAugT', 'Tvar:OptTsum', 
        #    'Tvar:AugMaxT', 'Tvar:maxT', 'Tvar:Acs', 'Tvar:drop5', 'Tvar:max.drop', 'Tvar:OctMin', 'Tvar:JanMin', 
        #    'Tvar:MarMin', 'Tvar:winterMin', 'Tvar:minT', 'Tvar:cv.gsp', 'Tvar:wd', 'Tvar:vpd', 'Tvar:mi', 
        #    'TOctSep:summerP1', 'TOctSep:summerP2', 'TOctSep:maxAugT', 'TOctSep:OptTsum', 'TOctSep:AugMaxT', 
        #    'TOctSep:maxT', 'TOctSep:Acs', 'TOctSep:drop0', 'TOctSep:drop5', 'TOctSep:max.drop', 'TOctSep:ddAugJul',
        #    'TOctSep:ddAugJun', 'TOctSep:OctMin', 'TOctSep:JanMin', 'TOctSep:MarMin', 'TOctSep:winterMin', 'TOctSep:minT', 
        #    'TOctSep:wd', 'TOctSep:vpd', 'TOctSep:mi', 'TOctSep:cwd', 'TOctSep:pt.coef', 'summerP1:summerP2', 
        #    'summerP1:Pmean', 'summerP1:POctSep', 'summerP1:PcumOctSep', 'summerP1:PPT', 'summerP1:maxAugT', 
        #    'summerP1:AugMaxT', 'summerP1:maxT', 'summerP1:Acs', 'summerP1:max.drop', 'summerP1:OctMin', 'summerP1:JanMin',
        #    'summerP1:MarMin', 'summerP1:winterMin', 'summerP1:minT', 'summerP1:wd', 'summerP1:mi', 'summerP1:cwd', 
        #    'summerP1:pt.coef', 'summerP2:Pmean', 'summerP2:POctSep', 'summerP2:PcumOctSep', 'summerP2:PPT', 
        #    'summerP2:maxAugT', 'summerP2:AugMaxT', 'summerP2:maxT', 'summerP2:max.drop', 'summerP2:ddAugJun', 
        #    'summerP2:OctMin', 'summerP2:JanMin', 'summerP2:MarMin', 'summerP2:winterMin', 'summerP2:minT', 
        #    'summerP2:wd', 'summerP2:mi', 'summerP2:cwd', 'summerP2:pt.coef', 'Pmean:POctSep', 'Pmean:PcumOctSep', 
        #    'Pmean:PPT', 'Pmean:maxAugT', 'Pmean:OptTsum', 'Pmean:AugMaxT', 'Pmean:maxT', 'Pmean:Acs', 'Pmean:drop0', 
        #    'Pmean:drop5', 'Pmean:max.drop', 'Pmean:ddAugJul', 'Pmean:ddAugJun', 'Pmean:OctMin', 'Pmean:JanMin', 
        #    'Pmean:MarMin', 'Pmean:winterMin', 'Pmean:minT', 'Pmean:cv.gsp', 'Pmean:wd', 'Pmean:vpd', 'Pmean:mi', 
        #    'Pmean:cwd', 'Pmean:pt.coef', 'POctSep:PcumOctSep', 'POctSep:PPT', 'POctSep:maxAugT', 'POctSep:OptTsum', 
        #    'POctSep:AugMaxT', 'POctSep:maxT', 'POctSep:Acs', 'POctSep:drop0', 'POctSep:drop5', 'POctSep:max.drop', 
        #    'POctSep:ddAugJul', 'POctSep:ddAugJun', 'POctSep:OctMin', 'POctSep:JanMin', 'POctSep:MarMin', 'POctSep:winterMin',
        #    'POctSep:minT', 'POctSep:cv.gsp', 'POctSep:wd', 'POctSep:vpd', 'POctSep:mi', 'POctSep:cwd', 'POctSep:pt.coef', 
        #    'PcumOctSep:PPT', 'PcumOctSep:maxAugT', 'PcumOctSep:OptTsum', 'PcumOctSep:AugMaxT', 'PcumOctSep:maxT', 
        #    'PcumOctSep:Acs', 'PcumOctSep:drop0', 'PcumOctSep:drop5', 'PcumOctSep:max.drop', 'PcumOctSep:ddAugJul', 
        #    'PcumOctSep:ddAugJun', 'PcumOctSep:OctMin', 'PcumOctSep:JanMin', 'PcumOctSep:MarMin', 'PcumOctSep:winterMin', 
        #    'PcumOctSep:minT', 'PcumOctSep:cv.gsp', 'PcumOctSep:wd', 'PcumOctSep:vpd', 'PcumOctSep:mi', 'PcumOctSep:cwd',
        #    'PcumOctSep:pt.coef', 'PPT:maxAugT', 'PPT:OptTsum', 'PPT:AugMaxT', 'PPT:maxT', 'PPT:Acs', 'PPT:drop0',
        #    'PPT:drop5', 'PPT:max.drop', 'PPT:ddAugJul', 'PPT:ddAugJun', 'PPT:OctMin', 'PPT:JanMin', 'PPT:MarMin', 
        #    'PPT:winterMin', 'PPT:minT', 'PPT:cv.gsp', 'PPT:wd', 'PPT:vpd', 'PPT:mi', 'PPT:cwd', 'PPT:pt.coef', 
        #    'maxAugT:AugMaxT', 'maxAugT:maxT', 'maxAugT:drop0', 'maxAugT:OctMin', 'maxAugT:JanMin', 'maxAugT:MarMin', 
        #    'maxAugT:winterMin', 'maxAugT:minT', 'maxAugT:cv.gsp', 'maxAugT:wd', 'maxAugT:vpd', 'maxAugT:mi', 'maxAugT:cwd', 
        #    'maxAugT:pt.coef', 'summerT40:AugMaxT', 'OptTsum:AugMaxT', 'OptTsum:maxT', 'OptTsum:Acs', 'OptTsum:drop5', 
        #    'OptTsum:max.drop', 'OptTsum:ddAugJul', 'OptTsum:ddAugJun', 'OptTsum:wd', 'OptTsum:vpd', 'OptTsum:mi', 
        #    'OptTsum:cwd', 'OptTsum:pt.coef', 'AugMaxT:maxT', 'AugMaxT:drop0', 'AugMaxT:drop5', 'AugMaxT:ddAugJul',
        #    'AugMaxT:ddAugJun', 'AugMaxT:MarMin', 'AugMaxT:cv.gsp', 'AugMaxT:wd', 'AugMaxT:vpd', 'AugMaxT:mi', 
        #    'AugMaxT:cwd', 'AugMaxT:pt.coef', 'maxT:drop0', 'maxT:drop5', 'maxT:ddAugJul', 'maxT:ddAugJun', 'maxT:MarMin', 
        #    'maxT:cv.gsp', 'maxT:wd', 'maxT:vpd', 'maxT:mi', 'maxT:cwd', 'maxT:pt.coef', 'Acs:drop5', 'Acs:max.drop', 
        #    'Acs:OctMin', 'Acs:JanMin', 'Acs:MarMin', 'Acs:winterMin', 'Acs:minT', 'Acs:vpd', 'Acs:pt.coef', 
        #    'drop0:max.drop', 'drop0:JanMin', 'drop0:MarMin', 'drop0:winterMin', 'drop0:minT', 'drop0:cwd', 'drop0:pt.coef', 
        #    'drop5:max.drop', 'drop5:OctMin', 'drop5:JanMin', 'drop5:MarMin', 'drop5:winterMin', 'drop5:minT', 'drop5:cv.gsp',
        #    'max.drop:OctMin', 'max.drop:JanMin', 'max.drop:MarMin', 'max.drop:winterMin', 'max.drop:minT', 'max.drop:cv.gsp', 
        #    'max.drop:vpd', 'max.drop:cwd', 'max.drop:pt.coef', 'ddAugJul:ddAugJun', 'ddAugJul:wd', 'ddAugJul:vpd', 
        #    'ddAugJul:mi', 'ddAugJul:cwd', 'ddAugJul:pt.coef', 'ddAugJun:wd', 'ddAugJun:vpd', 'ddAugJun:mi', 'ddAugJun:cwd',
        #    'ddAugJun:pt.coef', 'OctMin:JanMin', 'OctMin:MarMin', 'OctMin:winterMin', 'OctMin:minT', 'OctMin:cwd', 
        #    'OctMin:pt.coef', 'JanMin:MarMin', 'JanMin:winterMin', 'JanMin:minT', 'JanMin:cv.gsp', 'JanMin:cwd', 
        #    'JanMin:pt.coef', 'MarMin:winterMin', 'MarMin:minT', 'MarMin:cwd', 'MarMin:pt.coef', 'winterMin:minT', 
        #    'winterMin:cv.gsp', 'winterMin:cwd', 'winterMin:pt.coef', 'minT:cv.gsp', 'minT:cwd', 'minT:pt.coef', 
        #    'cv.gsp:wd', 'cv.gsp:mi', 'wd:vpd', 'wd:mi', 'wd:cwd', 'wd:pt.coef', 'vpd:mi', 'vpd:cwd', 'vpd:pt.coef', 
        #    'mi:cwd', 'mi:pt.coef', 'cwd:pt.coef']
        self.DROP = ['x.new', 'y.new', 'xy']

    def set_squares(self, squares):
        squares = squares if isinstance(squares, list) else [squares]
        self.SQUARE = squares

    def set_cubes(self, cubes):
        cubes = cubes if isinstance(cubes, list) else [cubes]
        self.CUBE = cubes

    def set_interactions(self, interactions):
        interactions = (interactions if isinstance(interactions, list)
                        else [interactions])
        self.INTERACTIONS = interactions

    def set_drop_columns(self, drops):
        self.DROP = drops if isinstance(drops, list) else [drops]
        
    def construct_model_matrices(self):
        train_X_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'X_train' in f])
        valid_X_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'X_valid' in f])
        test_X_files  = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'X_test' in f])
        train_y_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'y_train' in f])
        valid_y_files = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'y_valid' in f])
        test_y_files  = sorted(
            [f for f in os.listdir(self.DATA_DIR) if 'y_test' in f])
        print('Train:\n ', train_X_files, '\n ', train_y_files)
        print('Valid:\n ', valid_X_files, '\n ', valid_y_files)
        print('Test:\n ',  test_X_files,  '\n ', test_y_files)
        X_train = self._load_data_set(train_X_files)
        X_valid = self._load_data_set(valid_X_files)
        X_test  = self._load_data_set(test_X_files)
        y_train = self._load_data_set(train_y_files)
        y_valid = self._load_data_set(valid_y_files)
        y_test  = self._load_data_set(test_y_files)

        if self.DROP:
            X_train = X_train.drop(self.DROP, axis=1)
            X_valid = X_valid.drop(self.DROP, axis=1)
            X_test  = X_test.drop(self.DROP,  axis=1)
        data_sets = [
            [X_train, y_train], [X_valid, y_valid], [X_test, y_test]]
        for i, [X, y] in enumerate(data_sets):
            X = X.reindex()
            y = y.reindex()
            if 'density' in list(X):
                X = self._fill_na(X, 'density')
                y = y.loc[np.isnan(X['density']) == False, :]
                X = X.loc[np.isnan(X['density']) == False, :]
            X = self._add_all_cols(X.copy())
            X = X.reindex()
            y = y.reindex()
            data_sets[i] = [X, y]
        return data_sets

    def _load_data_set(self, set_files):
        print('Loading data from %s...' % set_files)
        data_set = pd.read_csv('%s/%s' % (self.DATA_DIR, set_files.pop()))
        for f in set_files:
            next_chunk = pd.read_csv('%s/%s' % (self.DATA_DIR, f))
            data_set = data_set.append(next_chunk)
        data_set.index = range(data_set.shape[0])
        return data_set

    def _add_all_cols(self, data_set):
        data_set = self._add_squares(data_set)
        data_set = self._add_cubes(data_set)
        data_set = self._add_interactions(data_set)
        return data_set
    
    def _add_squares(self, data_set):
        print('Adding quadratic terms...')
        for field in self.SQUARE:
            data_set['%s_sq' % field] = data_set[field] ** 2
        return data_set

    def _add_cubes(self, data_set):
        print('Adding cubic terms...')
        for field in self.CUBE:
            data_set['%s_cub' % field] = data_set[field] ** 3
        return data_set
    
    def _add_interactions(self, data_set):
        print('Adding interactions...')
        for field in self.INTERACTIONS:
            fields = field.split(':')
            if len(fields) == 2:
                f1, f2 = fields
                data_set[field] = data_set[f1] * data_set[f2]
            elif len(fields) == 3:
                f1, f2, f3 = fields
                data_set[field] = data_set[f1] * data_set[f2] * data_set[f3]
        return data_set

    def _fill_na(self, df, field):
        '''
        Fills value by taking the average of cells above and below (or just 
        one if both not available)
        '''
        print('Attempting to fill NAs with average of neighboring cells.')
        iterations = 0
        while sum(np.isnan(df[field])):
            for i in range(df.shape[0]):
                if np.isnan(df.loc[i, field]):
                    use = []
                    x = int(df.loc[i, 'x'])
                    x_above = int(df.loc[i - 1, 'x']) if i > 0 else np.nan
                    x_below = (int(df.loc[i + 1, 'x']) if i < df.shape[0] - 1
                               else np.nan)
                    if abs(x - x_above) == 1:
                        use.append(x_above)
                    if abs(x - x_below) == 1:
                        use.append(x_below)
                    if len(use):
                        df.loc[i, field] = np.mean(use)
            iterations += 1
            if iterations > 2:
                print('Could not fill %s for %d rows.'
                      % (field, sum(np.isnan(df[field]))))
                return df
        return df


# Test
#mod_matrix_constructor = ModelMatrixConstructor(
#    '../../data/Xy_internal_split_data')
#data_sets = mod_matrix_constructor.construct_model_matrices()
#print(list(data_sets[0][0]))
#print(list(data_sets[0][1]))
