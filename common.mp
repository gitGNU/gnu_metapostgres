% Copyright (C) 2017 Antonin Houska
%
% This file is part of MetaPostgres.
%
% MetaPostgres is free software: you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your option)
% any later version.
%
% MetaPostgres is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
% FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
% more details.
%
% You should have received a copy of the GNU General Public License along
% with MetaPostgres. If not, see <http://www.gnu.org/licenses/>.

numeric metapg.picturewidth;
numeric metapg.maxpicturewidth;
numeric metapg.scalefactor;

% If picture width exceeds this, the whole picture is scaled down so that the
% width (excluding the outermost line) equals to this value. However scaling
% does not affect thickness of lines / dashes.
%
% TODO Tune this so that it matches the PDF output.
metapg.maxpicturewidth := 5.5in;

% Accept color in the form of 3 hexadecimal numbers.
def hexrgbcolor(text r)(text g)(text b) =
  (hex r / 255, hex g / 255, hex b / 255)
enddef;


string setfntstr, fntsize;

setfntstr := "\font\fntcmtt = cmtt12 \fntcmtt ";
fntsize := "12pt";

% Maximum distance from letter baseline to the bottom of the containing vbox.
% Must include maximum depth of the font (not sure if font specifies this
% value explicitly) + space between the letter and the lower edge of the
% box. But it must not be to high, else the vbox will exceed the "vboxsize"
% value for some letters, causing their baselines to be misaligned.
numeric vboxdpth;

vboxdpth := 3pt;

string texstr;
picture texpic;

% Although the labels will be in separate boxes, we need baseline of them all
% to have the same y coordinate within the box. That is achieved by adding the
% appropriate \vskip below each letter.
%
% "bp" seems to be the output unit length of "decimal" operator.
def gettexstr(text t) =
  (setfntstr & "\newdimen\dpth\dpth=" & decimal vboxdpth & "bp\setbox0=\hbox{" &  t &
    "}\advance\dpth-\dp0\vbox to " & fntsize & "{\vfil\box0\vskip\dpth}")
enddef;

numeric labelborderx, labelbordery;

% Space between label and the surrounding line.
labelborderx := 6pt;
labelbordery := 2pt;

% Add equations to a label bounding box so that label picture can be put into
% it. (The equations only involve corners of the picture. User is responsible
% for positioning the whole label within the picture.)
def finalizelabel(text l) =
  l.ne = l.nw + (xpart(lrcorner l - llcorner l) + 2labelborderx, 0);
  l.sw = l.nw - (0, ypart(ulcorner l - llcorner l) + 2labelbordery);
  l.se = (xpart l.ne, ypart l.sw);
enddef;

% Put label "l" (in a form of picture) into its box, centered both
% horizontally and vertically.
def drawlabel(text l) =
  draw l shifted (
      % First, find the middle point of the lower edge ...
      (l.se + l.sw) / 2 -
      % ... then shift the lower left corner of the letter horizontally ...
      (lrcorner l - llcorner l) / 2 +
      % ... and move it the text upwards vertically.
      (0, labelbordery));
enddef;

% Explicit bounding box is useful if the picture contains multiple objects and
% computescalefactor() is needed.
pair	metapg.bbox.sw, metapg.bbox.nw, metapg.bbox.ne, metapg.bbox.se;

% Derive the bounding box from north-east and south-west corners.
%
% XXX If another pair of corners seems useful for some pictures, make the name
% of this macro more specific and define additional one.
def initboundingbox(text _nw, _se) =
  metapg.bbox.nw := _nw;
  metapg.bbox.se := _se;

  metapg.bbox.sw := (xpart _nw, ypart _se);
  metapg.bbox.ne := (xpart _se, ypart _nw);
enddef;

% The actual box will hardly find its way to pictures, but it can be useful
% to draw it for verification.
def drawboundingbox =
  draw metapg.bbox.nw--metapg.bbox.ne--metapg.bbox.se--metapg.bbox.sw--cycle;
enddef;

% The scalefactor is used to keep thickness of lines if the whole picture gets
% scaled down in order to fit metapg.maxpicturewidth. This macro should be
% followed by statement like this for each pen used:
%
% querypen := pencircle scaled (querypenwidth / metapg.scalefactor);
def computescalefactor(text bbox) =
  metapg.picturewidth := xpart bbox.se - xpart bbox.sw;
  if metapg.picturewidth > metapg.maxpicturewidth:
    metapg.scalefactor :=  metapg.maxpicturewidth / metapg.picturewidth;
  else:
    metapg.scalefactor := 1;
  fi
enddef;

% Adjust the query size per 'finalscale' variable, which should be specified
% on command line.
def fixpicturewidth =
  if finalscale = 0:
    finalscale := 100;
  fi;

  if metapg.scalefactor < 1:
    finalscale := finalscale * metapg.scalefactor;
  fi;

  currentpicture := currentpicture scaled (finalscale / 100);
enddef;
