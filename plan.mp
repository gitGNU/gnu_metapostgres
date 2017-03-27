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

% Macros to draw query plan tree.

% Space between plan nodes.
numeric plannodespacing;
plannodespacing := .5in;

% Space between the noden contents and the outer edge, or between node
% components. XXX Invent better name, as it's not always used for border.
numeric planborder;
planborder := 6pt;

numeric plannodes[].ninputs;

% Corners of the node box respectively.
pair plannodes[].sw, plannodes[].se, plannodes[].ne, plannodes[].nw;

% The middle of the south and north edges. (Western and easter are not needed
% -- add them when / if needed.)
%pair plannodes[].s, plannodes[].n;

picture plannodes[].name;
pair plannodes[].name.nw, plannodes[].name.ne, plannodes[].name.sw,
  plannodes[].name.se;

picture	plannodes[].qual;
pair plannodes[].qual.nw, plannodes[].qual.ne, plannodes[].qual.sw,
  plannodes[].qual.se;

% Points to connect the node with input and output plans.
pair plannodes[].lefttree, plannodes[].righttree, plannodes[].result;

numeric currenplannode;
currentplannode := -1;

pen planpen, arrowpen;
numeric planpenwidth, arrowpenwidth;
planpenwidth := 1;
arrowpenwidth := .5;

% If arrow changes direction, this variable controls sharpness of the break.
numeric arrowelbowradius;
arrowelbowradius = 6pt;

def adjustplanpens =
  planpen := pencircle scaled (planpenwidth / metapg.scalefactor);
  arrowpen := pencircle scaled (arrowpenwidth / metapg.scalefactor);
enddef;

def createplannode(text kind) =
  currentplannode := incr(currentplannode);

  if kind = "seqscan":
    plannodes[currentplannode].ninputs := 1;
    plannodes[currentplannode].name := TEX gettexstr("SeqScan");
  elseif kind = "join":
    plannodes[currentplannode].ninputs := 2;
    plannodes[currentplannode].name := TEX gettexstr("Join");
  else:
    % Tell user that the node kind was not recognized.
    plannodes[currentplannode].name := "XXXXXX";
  fi;
enddef;

def setplanqual(text n) =
  plannodes[currentplannode].qual := TEX gettexstr(n);
enddef;

def finalizeplannode(suffix pidx) =
  numeric	maxtextwidth, heightextra;

  heightextra := 0;

  % If the node has a qualifier, it does affect node height, and maybe the
  % width as well.
  if known plannodes.pidx.qual:
    heightextra :=
      ypart (ulcorner plannodes.pidx.qual -
      	llcorner plannodes.pidx.qual) + planborder;
  fi;

  % Height of the whole node.
  plannodes.pidx.nw - plannodes.pidx.sw =
      (0, ypart(plannodes.pidx.name.nw - plannodes.pidx.name.sw) +
	2planborder + heightextra);

  maxtextwidth := xpart(lrcorner plannodes.pidx.name - llcorner
      plannodes.pidx.name);

  if known plannodes.pidx.qual:
    if (xpart (lrcorner plannodes.pidx.qual - llcorner plannodes.pidx.qual) >
	maxtextwidth):
      % If the qualifier is wider than the name, it should control the width
      % of the whole node.
	maxtextwidth := xpart (lrcorner plannodes.pidx.qual -
	  llcorner plannodes.pidx.qual);
    fi;
  fi;

  plannodes.pidx.se - plannodes.pidx.sw = + (maxtextwidth + 2labelborderx +
      2planborder, 0);

  plannodes.pidx.se - plannodes.pidx.sw =
    plannodes.pidx.ne - plannodes.pidx.nw;
  plannodes.pidx.ne - plannodes.pidx.se =
    plannodes.pidx.nw - plannodes.pidx.sw;

  % Name label.
  plannodes.pidx.name.nw = plannodes.pidx.nw + (planborder, -planborder);
  finalizelabel(plannodes.pidx.name);

  % Qualifier, if there is one.
  if known plannodes.pidx.qual:
    plannodes.pidx.qual.nw = plannodes.pidx.name.sw - (0, planborder);
    finalizelabel(plannodes.pidx.qual);
  fi;

  % Points where the input nodes should get connected.
  if plannodes.pidx.ninputs = 1:
    plannodes.pidx.lefttree = .5[plannodes.pidx.sw, plannodes.pidx.se];
  else:
    % Only join should have both left and right tree.
    plannodes.pidx.lefttree = 1/3[plannodes.pidx.sw, plannodes.pidx.se];
    plannodes.pidx.righttree = 2/3[plannodes.pidx.sw, plannodes.pidx.se];
  fi;

  % There's always a single output.
  plannodes.pidx.result = .5[plannodes.pidx.nw, plannodes.pidx.ne];
enddef;

% Attach an input node to a node which requires exactly one input node.
def attachsingleinput(text node)(text left) =
  node.lefttree = left.n + (0, plannodespacing);
enddef;

% Attach input nodes to a join node.
%
% Position of the input nodes must be well defined even w/o the equations that
% we add here.
def attachjoininputs(text node)(text left)(text right) =
  % If y-coordinate of northern edge of the the input nodes differs, the
  % higher one controls the y-coordinate of the join node's southern edge.
  if ypart left.n > ypart right.n:
    % Each input node should be at the same distance from the vertical axe of
    % the join node.
    left.ne + .5(right.nw - left.ne) + (0, plannodespacing)
      = .5[node.lefttree, node.righttree];
  else:
    % The same, except that the right node gives us the y-coordinate.
    right.nw - .5(right.nw - left.ne) + (0, plannodespacing) =
      .5[node.lefttree, node.righttree];
  fi;
enddef;

def drawplannode(suffix pidx) =
  pickup planpen;

  draw plannodes.pidx.sw--plannodes.pidx.nw--plannodes.pidx.ne--
    plannodes.pidx.se--cycle;

  drawlabel(plannodes.pidx.name);
  if known plannodes.pidx.qual:
    drawlabel(plannodes.pidx.qual);
  fi;
enddef;

% Draw arrow from the input table to generic plan.
def drawsimpleplaninputarrow(text _plan)(text _input) =
  pickup arrowpen;

  drawarrow _input.n -- _plan.lefttree;
enddef;

% Draw arrow from the input table to join plan.
def drawjoininputarrow(expr _from, _to) =
  % The lower vertical line.
  draw _from--(xpart _from, ypart (.5[_from, _to]) - arrowelbowradius);

  if xpart _from < xpart _to:
    % The elbow from vertical to horizontal direction.
    draw (xpart _from, ypart (.5[_from, _to]) - arrowelbowradius){0,1}..
      {1, 0}(xpart _from + arrowelbowradius, ypart (.5[_from, _to]));

    % Horizontal line.
    draw (xpart _from + arrowelbowradius, ypart (.5[_from, _to]))--
      (xpart _to - arrowelbowradius, ypart (.5[_from, _to]));

    % The elbow from horizontal to vertical direction.
    draw (xpart _to - arrowelbowradius, ypart (.5[_from, _to])){1, 0}..
      {0, 1}(xpart _to, ypart (.5[_from, _to]) + arrowelbowradius);
  else:
    draw (xpart _from, ypart (.5[_from, _to]) - arrowelbowradius){0, 1}..
      {-1, 0}(xpart _from - arrowelbowradius, ypart (.5[_from, _to]));

    draw (xpart _from - arrowelbowradius, ypart(.5[_from, _to]))--
      (xpart _to + arrowelbowradius, ypart (.5[_from, _to]));

    draw (xpart _to + arrowelbowradius, ypart (.5[_from, _to])){-1, 0}..
      {0, 1}(xpart _to, ypart (.5[_from, _to]) + arrowelbowradius);
  fi;

  % The upper vertical line.
  drawarrow (xpart _to, ypart (.5[_from, _to]) + arrowelbowradius)--_to;
enddef;

def drawjoininputarrows(text _plan)(text _left)(text _right) =
  pickup arrowpen;

  drawjoininputarrow(_left.n, _plan.lefttree);
  drawjoininputarrow(_right.n, _plan.righttree);
enddef;

% Draw arrow from the plan node to the output table.
def drawplanoutputarrow(text _plan)(text _output) =
  pickup arrowpen;

  drawarrow _plan.result -- _output.s;
enddef;
