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

% Macros to draw parsed query tree.
%
% Note on filling: for some reason it looks better if area is first filled,
% and the boundary is drawn. (Otherwise the boundary looks thinner than
% expected.)

numeric colminwidth, colheight, opwidth, opheight, spacing;

% Space between box components.
spacing := 6pt;

% Total height and height of the box containing column name.
colheight := 18pt;

% Minimum width of the box containing column name.
colminwidth := 18pt;

% The same for operator box.
opwidth := 24pt;
opheight := 18pt;

color defcolbgcolor, outcolbgcolor, tablenamebgcolor, tablebgcolor;
color joinnamebgcolor, querynamebgcolor;
color colbgcolor[];

defcolbgcolor := hexrgbcolor("C1")("F8")("FF");
outcolbgcolor := hexrgbcolor("74")("E4")("F2");

color querybgcolor[];
numeric querylevel;

% Default (background) color of a column.
querybgcolor[0] := hexrgbcolor("FF")("F8")("CE");
querybgcolor[1] := hexrgbcolor("CF")("C9")("A7");
querylevel := 0;
querynamebgcolor := hexrgbcolor("E3")("E5")("E8");

color fromlistbgcolor;

fromlistbgcolor := hexrgbcolor("F0")("F2")("4A");

color joinbgcolor[];
numeric	joinlevel;

joinbgcolor[0] := hexrgbcolor("FF")("A2")("A4");
joinbgcolor[1] := hexrgbcolor("FF")("7E")("80");
joinnamebgcolor := hexrgbcolor("E3")("E5")("E8");
joinlevel := 0;

tablebgcolor := hexrgbcolor("FD")("BD")("5D");
tablenamebgcolor := hexrgbcolor("E3")("E5")("E8");

color opboxbgcolor;

opboxbgcolor := hexrgbcolor("A6")("6E")("FF");

color constboxbgcolor;

constboxbgcolor := hexrgbcolor("A6")("6E")("00");

numeric i;

% querypefn, colpen, oppen and arrow pen are pens used to draw the query (or
% its components, such as tables or joins), column boxes, operator boxes and
% arrows respectively.
pen querypen, colpen, oppen, arrowpen;
numeric querypenwidth, colpenwidth, oppenwidth,arrowpenwidth;

% Since pencircle accepts factor of the PostScript point, these values can
% also be considered of this unit.
querypenwidth := 1;
colpenwidth := .5;
oppenwidth := .5;
arrowpenwidth := .5;

def adjustquerypens =
  querypen := pencircle scaled (querypenwidth / metapg.scalefactor);
  colpen := pencircle scaled (colpenwidth / metapg.scalefactor);
  oppen := pencircle scaled (oppenwidth / metapg.scalefactor);
  arrowpen := pencircle scaled (arrowpenwidth / metapg.scalefactor);
enddef;

picture exletter;

exletter := TEX gettexstr("x");
def exunit =
  (xpart ((lrcorner exletter) - (llcorner exletter)))
enddef;

def getcolwidth(expr p) =
  if (xpart (lrcorner p - llcorner p)) > exunit:
    colminwidth - exunit + (xpart (lrcorner p - llcorner p))
  else:
    colminwidth
  fi
enddef;


% Pictures representing operators, for repeated reuse.
picture opeq;

opeq := TEX gettexstr("=");

% Define common fields of a range table entry (RTE).
def createrte(text r) =
  % 't' - table, 'j' - join, 'q' - query.
  string r.kind;

  % North, west, south, ... etc. of the whole box.
  pair r.n, r.w, r.s, r.e, r.nw, r.sw, r.se, r.ne;

  % Number of columns.
  numeric r.ncols;

  % Output column labels.
  picture r.col[];

  % Column widths.
  numeric r.colwidth[];

  % Per-column reference points.
  pair r.col[].n, r.col[].w, r.col[].s, r.col[].e, r.col[].nw, r.col[].sw,
    r.col[].se, r.col[].ne;

  % Background color of the column box.
  color	r.col[].bgcolor;

  % Name label.
  picture r.name;

  % Box the name will be placed into.
  pair r.name.nw, r.name.sw, r.name.se, r.name.ne;

  % Height of the qualifier box that makes this RTE participate in a join.
  % (It should be zero if there's no join above us.)
  %
  % XXX Currently the variable includes one spacing unit before the first qual
  % and one after that. Consider moving these spacing to the adjacent
  % componsnts, the related equations might get easier to read.
  numeric r.upperqualheight;
enddef;

% This macro only defines variables that the other ones will use. The general
% approach is to build everything from scratch and to include all elements
% into linear equations.
%
% Note: It might seem easier to use "boxes" package, but such approach does
% not allow references to a containing and contained boxes at the same time:
% the contained box needs to be finalized before we start constructing the
% containing one, but the reference points ("n", "w", "s", "e", ...) are not
% recomputed after the containing box has been finalized.
def createtable(text t) =
  createrte(t);

  t.kind := "t";

  % Distance between western side of the first column and eastern of the last
  % one.
  numeric	t.colwidthtotal;
enddef;

vardef addrtecols@#(text t) =
  pair c;
  numeric i;
  picture p;

  i := 0;
  @#.colwidthtotal := 0;

  for c=t:
    texstr := gettexstr(c);
    @#.col[i] := TEX texstr;

    if i = 0:
      @#.col[i].nw = @#.nw + (spacing, -spacing);
    else:
      @#col[i].nw = @#.col[i-1].ne;
    fi

    @#col[i].sw = @#col[i].nw - (0, colheight);

    @#.colwidth[i] := getcolwidth(@#.col[i]);
    @#.col[i].ne = @#.col[i].nw + (@#.colwidth[i], 0);
    @#.col[i].se - @#.col[i].sw = @#.col[i].ne - @#.col[i].nw;

    @#.colwidthtotal := @#.colwidthtotal + @#.colwidth[i];

    % Middle points of column box edges. XXX Do we also need east and west?
    % @#.col[i].n = (@#.col[i].ne + @#.col[i].nw) / 2;
    % @#.col[i].s = (@#.col[i].se + @#.col[i].sw) / 2;

    @#.col[i].bgcolor := defcolbgcolor;

    i := incr(i);
  endfor

  @#.ncols := i;
enddef;

% Mark output columns of an RTE entry.
%
% If used in front of finalizequery(), the corresponding columns of the owning
% join adopt the "output color". If these columns are not output of the join,
% use this macro *after* finalizequery().
vardef setoutcols@#(text t) =
  numeric c;
  numeric i;

  i := 0;

  for c=t:
    @#.col[c].bgcolor := outcolbgcolor;
  endfor;
enddef;

vardef settablename@#(text t) =
  texstr := gettexstr(t);
  texpic := TEX texstr;
  @#.name := texpic;
enddef;

% Add still-missing equations.
def finalizetable(text t) =
  numeric namewidth, nameheight;

  % Dimensions of t.name are constants for us (fixed by TeX).
  namewidth := xpart(lrcorner t.name - llcorner t.name) + 2labelborderx;
  nameheight := ypart(ulcorner t.name - llcorner t.name) + 2labelbordery;

  t.name.nw = t.name.sw + (0, nameheight);
  t.name.ne - t.name.se = t.name.nw - t.name.sw;
  t.name.ne - t.name.nw = (namewidth, 0);
  t.name.se - t.name.sw = t.name.ne - t.name.nw;

  % Position the label, relative to the outer box.
  t.sw = t.name.sw - (spacing, spacing);

  % The east side is determined by the right edge of the last column box or by
  % that of the name box - whichever has higher ypart.
  if t.colwidthtotal > namewidth:
    t.se = t.sw + (t.colwidthtotal + 2spacing, 0);
  else:
    t.se = t.sw + (namewidth + 2spacing, 0);
  fi

  t.nw - t.sw = (0, t.upperqualheight + nameheight + colheight + 4spacing);
  t.ne - t.se = t.nw - t.sw;

  % Edge middle points. XXX Do we also need north and south?
  t.e = (t.ne + t.se) / 2;
  t.w = (t.nw + t.sw) / 2;
enddef;

def drawtable(text t) =
  numeric i;
  path p;

  % The outer box.
  p := t.nw--t.sw--t.se--t.ne--cycle;
  fill p withcolor tablebgcolor;
  pickup querypen;
  draw p;

  % Columns.
  for i=0 upto t.ncols - 1:
    % Draw the column box ...
    p := t.col[i].nw--t.col[i].sw--t.col[i].se--t.col[i].ne--cycle;
    fill p withcolor t.col[i].bgcolor;
    pickup colpen;
    draw p;

    drawlabel(t.col[i]);
  endfor;

  % Likewise, box for the table name ... (Not sure if this component deserves
  % a boundary - the fact that it is a tree node is not important when
  % explaining planner concepts. If adding the boundary later, dedicate
  % special pen to it.)
  p := t.name.nw--t.name.sw--t.name.se--t.name.ne--cycle;
  fill p withcolor tablenamebgcolor;

  % ... and the name itself.
  drawlabel(t.name);
enddef;

% Create box to contain relations as well as (ANDed) qualifiers.
def createjoin(text j) =
  createrte(j);

  % Number of join qualifiers.
  numeric j.nquals;

  numeric j.height;

  % Per-qualifier labels.
  picture j.qual[];

  % Per-qualifier points.
  pair j.qual[].n, j.qual[].w, j.qual[].s, j.qual[].e, j.qual[].nw,
    j.qual[].sw, j.qual[].se, j.qual[].ne;

  % For each qualifier these variables store endpoits of the arrows pointing
  % to the referenced columns.
  pair j.qual[].lend, j.qual[].rend;

  % Points of alias (i.e. output) columns.
  pair j.col[].n, j.col[].w, j.col[].s, j.col[].e, j.col[].nw, j.col[].sw,
    j.col[].se, j.col[].ne;

  j.kind := "j";

  j.nquals := 0;
enddef;

% Add label and equations to operator box.
def finalizequal(text q, oppic) =
  q := oppic;
  q.nw + (opwidth, 0) = q.ne;
  q.sw + (opwidth, 0) = q.se;
  q.ne - (0, opheight) = q.se;
  q.nw - (0, opheight) = q.sw;
  q.n = 0.5[q.ne, q.nw];
  q.s = 0.5[q.se, q.sw];
  q.w = 0.5[q.nw, q.sw];
  q.e = 0.5[q.ne, q.se];
enddef;

% Add a single qualifier to a join. "l" and "r" are (0-based) numbers of the
% referenced columns of the left and the right table respectively.
%
% oppic is a picture containing the operator string.
vardef addjoinqual@#(text l, r, oppic) =
  finalizequal(@#.qual[@#.nquals])(oppic);

  if @#.nquals > 0:
    % Each next operator box is located below the previous one. "spacing" is
    % gap between the adjacent boxes.
    @#.qual[@#.nquals - 1].se - (0, spacing) = @#.qual[@#.nquals].ne;
    @#.qual[@#.nquals - 1].sw - (0, spacing) = @#.qual[@#.nquals].nw;
  fi

  @#.qual[@#.nquals].lend = .5[@#.left.col[l].sw, @#.left.col[l].se];
  @#.qual[@#.nquals].rend = .5[@#.right.col[r].sw, @#.right.col[r].se];

  @#.nquals := incr(@#.nquals);
enddef;

def finalizejoin(text j) =
  numeric i, n;
  numeric namewidth, nameheight;

  % The upper edge of the upper-most qualifier should be located below the
  % lower edge of columns, so that we can then draw arrows from east / west
  % edges of the qualifiers to south edges of columns.
  j.qual[0].nw = (xpart j.left.ne + 2spacing,
      ypart j.left.col[0].se - 2spacing);
  j.qual[0].nw + (opwidth, 0) = (xpart j.right.nw - 2spacing,
      ypart j.right.col[0].sw - 2spacing);

  % Likewise, the lower edge must be above the relation name boxes.
  j.qual[j.nquals - 1].sw = (xpart j.left.se + 2spacing,
      ypart j.qual[0].nw - j.left.upperqualheight + 2spacing);
  j.qual[j.nquals - 1].sw + (opwidth, 0) = (xpart j.right.sw - 2spacing,
      ypart j.qual[0].nw - j.right.upperqualheight + 2spacing);

  if j.left.kind = "j":
    finalizejoin(j.left);
  elseif j.left.kind = "q":
    finalizequery(j.left);
  else:
    finalizetable(j.left);
  fi;

  if j.right.kind = "j":
    finalizejoin(j.right);
  elseif j.left.kind = "q":
    finalizequery(j.right);
  else:
    finalizetable(j.right);
  fi;

  % Dimensions of j.name are constants for us (fixed by TeX).
  namewidth := xpart(lrcorner j.name - llcorner j.name) + 2labelborderx;
  nameheight := ypart(ulcorner j.name - llcorner j.name) + 2labelbordery;

  j.name.nw = j.name.sw + (0, nameheight);
  j.name.ne - j.name.se = j.name.nw - j.name.sw;
  j.name.ne - j.name.nw = (namewidth, 0);
  j.name.se - j.name.sw = j.name.ne - j.name.nw;

  % Position the label, relative to the outer box.
  j.sw = j.name.sw - (spacing, spacing);

  % Outer box of the whole join.
  j.nw = j.left.nw + (-spacing, 3spacing + j.upperqualheight + colheight);
  j.ne = j.right.ne + (spacing, 3spacing + j.upperqualheight + colheight);

  j.name.nw = j.left.sw - (0, 2spacing);
  j.name.sw = j.name.nw - (0, nameheight);
  j.sw = j.name.sw - (spacing, spacing);

  j.se = j.right.se + (spacing, -(3spacing + nameheight));

  % Make sure the outer box is rectangle even if the left relation has
  % different height from the right one.
  if ypart j.se > ypart j.sw:
    j.se := (xpart j.se, ypart j.sw);
  elseif  ypart j.sw > ypart j.se:
    j.sw := (xpart j.sw, ypart j.se);
  fi;

  % Construct boxes for the alias (output) columns.
  j.ncols := j.left.ncols + j.right.ncols;
  n := 0;
  for i=0 upto j.ncols - 1:
    if n = 0:
      j.col[n].nw = j.nw + (spacing, -spacing);
    else:
      j.col[n].nw = j.col[n - 1].ne;
    fi;

    j.col[n].sw = j.col[n].nw - (0, colheight);
    j.col[n].se - j.col[n].sw = j.col[n].ne - j.col[n].nw;

    % Label and background color.
    if n < j.left.ncols:
      j.col[n] := j.left.col[n];
      j.col[n].bgcolor := j.left.col[n].bgcolor;

      j.colwidth[n] := j.left.colwidth[n];
    else:
      j.col[n] := j.right.col[n - j.left.ncols];
      j.col[n].bgcolor := j.right.col[n - j.left.ncols].bgcolor;

      j.colwidth[n] := j.right.colwidth[n - j.left.ncols];
    fi;
    j.col[n].ne = j.col[n].nw + (j.colwidth[n], 0);

    n := incr(n);
  endfor;
enddef;

% Operator box is depicted as an ellipse.
def drawopbox(text op) =
  pickup oppen;
  p := op.w..op.n..op.e..op.s..cycle;
  fill p withcolor opboxbgcolor;
  draw p;

  drawlabel(op);
enddef;

def drawjoin(text j) =
  path p;

  p := j.nw--j.ne--j.se--j.sw--cycle;
  fill p withcolor joinbgcolor[joinlevel];
  pickup querypen;
  draw p;

  if j.left.kind = "j":
    joinlevel := incr(joinlevel);
    drawjoin(j.left);
    joinlevel := decr(joinlevel)
  elseif j.left.kind = "q":
    querylevel := incr(querylevel);
    drawquery(j.left);
    querylevel := decr(querylevel);
  else:
    drawtable(j.left);
  fi;

  if j.right.kind = "j":
    joinlevel := incr(joinlevel);
    drawjoin(j.right);
    joinlevel := decr(joinlevel);
  elseif j.left.kind = "q":
    querylevel := incr(querylevel);
    drawquery(j.right);
    querylevel := decr(querylevel);
  else:
    drawtable(j.right);
  fi;

  for i=0 upto j.nquals - 1:
    drawopbox(j.qual[i]);

    pickup arrowpen;
    drawarrow j.qual[i].w{left}...{up}j.qual[i].lend;
    drawarrow j.qual[i].e{right}...{up}j.qual[i].rend;
  endfor;

  % Columns.
  for i=0 upto j.ncols - 1:
    p := j.col[i].nw--j.col[i].sw--j.col[i].se--j.col[i].ne--cycle;
    fill p withcolor j.col[i].bgcolor;
    pickup colpen;
    draw p;

    pickup arrowpen;
    drawlabel(j.col[i]);
  endfor;

  % Name
  fill j.name.nw--j.name.sw--j.name.se--j.name.ne--cycle
    withcolor joinnamebgcolor;
  drawlabel(j.name);
enddef;

% Create variables that represent FROM list of a query.
def createfromlist(text q) =
  % Per-qualifier labels.
  picture q.fromlist.qual[];

  pair q.fromlist.nw, q.fromlist.sw, q.fromlist.se, q.fromlist.ne;

  % Comma-separated list of items.
  string q.fromlist;

  % Upper-right (north-east) corner of i-th (0-based) item. Used in equations
  % that determine horizontal spacing of the list items.
  pair q.fromlist.ne[];

  % x coordinate of the i-th item that qual should consider the items' eastern
  % edge if the item is on the left side of the qual. See addwherequal() for
  % details.
  numeric q.fromlist.lefteast[];

  % Likewise, x coordinate to be considered the west edge if the item is on
  % the right side of a qual.
  numeric q.fromlist.rightwest[];

  % Upper edge of the qualifier.
  numeric q.fromlist.north[];

  % The "row" argument passed to addwherequal().
  numeric q.fromlist.rownr[];

  % Qualifiers of the FROM list.
  pair q.fromlist.qual[].n, q.fromlist.qual[].w, q.fromlist.qual[].s,
    q.fromlist.qual[].e, q.fromlist.qual[].nw, q.fromlist.qual[].sw,
    q.fromlist.qual[].ne, q.fromlist.qual[].se;
  pair q.fromlist.qual[].lend, q.fromlist.qual[].rend;
  numeric q.fromlist.nquals;

  q.fromlist := "";
  q.fromlist.nquals := 0;
enddef;

% Remember all the items by putting them into a string that we will turn back
% to tokens and iterate later.
vardef addfromitems@#(text t) =
  numeric i;

  i := 0;
  forsuffixes c=t:
    if i > 0:
      @#.fromlist := @#.fromlist & ",";
    fi;
    @#.fromlist := @#.fromlist & str c;
    i := incr(i);
  endfor;
enddef;

% Make sure all items of the FROM list do have enough vertical space for
% qualifiers and arrows. "n" is the maximum number of qualifiers referencing
% particular pair of tables.
def setqualheight(text t, n) =
  numeric i, h;

  i := 0;
  h := 2spacing + n * opheight + (n - 1) * spacing;
  forsuffixes c=scantokens t:
    c.upperqualheight := h;
  endfor;
enddef;

% Define relationships between components.
def finalizequery(text q) =
  numeric i;
  numeric namewidth, nameheight;

  i := 0;
  forsuffixes c=scantokens q.fromlist:
    if i = 0:
      % West side of the outer box of the from list is derived from the 0-th
      % item.
      q.fromlist.nw = c.nw + (-spacing, spacing);
      q.fromlist.sw = c.sw - (spacing, spacing);
    fi;

    q.fromlist.ne[i] = c.ne;

    if i > 0:
      % Leave at 2spacing on each side of the (column of) operator boxes, like
      % we do between join sides. (Plus 2spacing space on each side, as we do
      % with joins.)
      q.fromlist.ne[i - 1] + (opwidth + 4spacing, 0) = c.nw;
    fi;

    begingroup save i;
      if c.kind = "j":
	finalizejoin(c);
      elseif c.kind = "q":
	finalizequery(c);
      else:
	finalizetable(c);
      fi;
    endgroup;

    i := incr(i);
  endfor;

  % TODO Create a new macro to reuse the corresponding code of
  % finalizetable(). (And do the same in finalizejoin().)
  if known q.name:
    namewidth := xpart(lrcorner q.name - llcorner q.name) + 2labelborderx;
    nameheight := ypart(ulcorner q.name - llcorner q.name) + 2labelbordery;
    q.name.nw = q.name.sw + (0, nameheight);
    q.name.ne - q.name.se = q.name.nw - q.name.sw;
    q.name.ne - q.name.nw = (namewidth, 0);
    q.name.se - q.name.sw = q.name.ne - q.name.nw;
    q.name.nw = q.fromlist.sw - (0, 2spacing);
    q.sw = q.name.sw - (spacing, spacing);
  else:
    q.sw = q.fromlist.sw - (spacing, spacing);
  fi;

  % FROM list eastern edge should usually control the eastern edge of the
  % whole query.
  %
  % XXX Should the query have too many output columns, we need to add a flag
  % that user sets, because values haven't been computed yet. If the flag
  % indicates so, the eastern edge of the query will be derived either from
  % column list of query name, whichever reaches the higher x coordinate.
  q.ne = (xpart q.fromlist.ne + spacing, ypart q.nw);
  q.ne - q.se = q.nw - q.sw;

  % East side of the outer box of the from list is derived from the last item.
  q.fromlist.ne = q.fromlist.ne[i - 1] + (spacing, spacing);
  q.fromlist.se = (xpart q.fromlist.ne, ypart q.fromlist.sw);

  % Position the output columns.
  q.col[0].sw = q.fromlist.nw + (0, 2spacing + q.upperqualheight);
  q.col[0].nw = q.col[0].sw + (0, colheight);
enddef;

def drawquery(text q) =
  path p;

  joinlevel := 0;

  % The query outer box.
  pickup querypen;
  p := q.sw--q.nw--q.ne--q.se--cycle;
  fill p withcolor querybgcolor[querylevel];
  draw p;

  % The FROM list outer box.
  p := q.fromlist.nw--q.fromlist.sw--q.fromlist.se--q.fromlist.ne--cycle;
  fill p withcolor fromlistbgcolor;
  draw p;

  forsuffixes c=scantokens q.fromlist:
    if c.kind = "j":
      drawjoin(c);
    elseif c.kind = "q":
      querylevel := incr(querylevel);
      drawquery(c);
      querylevel := decr(querylevel);
    else:
      drawtable(c);
    fi;
  endfor;

  % Output columns.
  for i=0 upto q.ncols - 1:
    p := q.col[i].nw--q.col[i].sw--q.col[i].se--q.col[i].ne--cycle;
    fill p withcolor q.col[i].bgcolor;
    pickup colpen;
    draw p;

    drawlabel(q.col[i]);
  endfor;

  % Name
  if known q.name:
    fill q.name.nw--q.name.sw--q.name.se--q.name.ne--cycle
      withcolor querynamebgcolor;
    drawlabel(q.name);
  fi;
enddef;

% Add a qualifier to the FROM list (which is effectively a WHERE clause
% qualifier), referencing cl-th and cr-th (both 0-based) columns of "l" and
% "r" item of the FROM list respectively. "row" is (0-based) sequence number
% of the qualifier for particular pair of relations. (Thus it determines
% vertical position of the qualifier.)
%
% Note that this macro should not be used until position of all RTEs in the
% picture is finalized.
%
% TODO
%
% Consider remembering the number of qualifiers per relation pair and deriving
% "row" automatically.
vardef addwherequal@#(text l, cl, r, cr, row, oppic) =
  @#.fromlist.qual[@#.fromlist.nquals] := oppic;

  % Qualifier box and the referenced table should never overlap.
  %
  % Join should always have horizontal space between the last column and the
  % outer edge, so it's ok if the qualifier boxes are placed inside the join
  % box.
  %
  % The same is usually true for a subquery, but not always: it can contain a
  % single table, and in addition it can have more output columns than the
  % table. In that case we need to tread it like a table, i.e. locate the qual
  % box outside.
  %
  % Since addwherequal() needs to have the FROM list items finalized anyway,
  % we can do the choice "at runtime". (No need for extra info from user.)
  if xpart l.ne - xpart l.col[l.ncols - 1].se - 2spacing >= colminwidth:
    @#.fromlist.lefteast[@#.fromlist.nquals] = xpart l.col[l.ncols - 1].se + spacing;
  else:
    @#.fromlist.lefteast[@#.fromlist.nquals] = xpart l.ne;
  fi;

  % There's nothing specific about the right relation.
  @#.fromlist.rightwest[@#.fromlist.nquals] = xpart.r.nw;

  % The north edge of the upper-most qualifier is located 2 spacing units
  % below the lower edge of columns (it shouldn't matter whether we reference
  % columns of the left or the right relation): one spacing unit between the
  % column edge and the "qualifier container", the other between the container
  % and the qual itself. Each next qual is located one spacing unit below the
  % previous one.
  @#.fromlist.north[@#.fromlist.nquals] = ypart l.col[0].sw - 2spacing -
    row * (spacing + opheight);

  % Compute corners of the qualifier box.
  @#.fromlist.qual[@#.fromlist.nquals].nw =
    (@#.fromlist.lefteast[@#.fromlist.nquals] +
      (@#.fromlist.rightwest[@#.fromlist.nquals] -
	@#.fromlist.lefteast[@#.fromlist.nquals] - opwidth) / 2,
      @#.fromlist.north[@#.fromlist.nquals]);

  @#.fromlist.qual[@#.fromlist.nquals].nw + (opwidth, 0) =
    @#.fromlist.qual[@#.fromlist.nquals].ne;

  @#.fromlist.qual[@#.fromlist.nquals].nw - (0, opheight) =
    @#.fromlist.qual[@#.fromlist.nquals].sw;

  @#.fromlist.qual[@#.fromlist.nquals].se =
    (xpart @#.fromlist.qual[@#.fromlist.nquals].ne,
     ypart @#.fromlist.qual[@#.fromlist.nquals].sw);

  @#.fromlist.qual[@#.fromlist.nquals].n =
    0.5[@#.fromlist.qual[@#.fromlist.nquals].nw,
      @#.fromlist.qual[@#.fromlist.nquals].ne];

  @#.fromlist.qual[@#.fromlist.nquals].s =
    0.5[@#.fromlist.qual[@#.fromlist.nquals].sw,
      @#.fromlist.qual[@#.fromlist.nquals].se];

  @#.fromlist.qual[@#.fromlist.nquals].w =
    (@#.fromlist.qual[@#.fromlist.nquals].nw +
      @#.fromlist.qual[@#.fromlist.nquals].sw) / 2;

  @#.fromlist.qual[@#.fromlist.nquals].e =
    (@#.fromlist.qual[@#.fromlist.nquals].ne +
      @#.fromlist.qual[@#.fromlist.nquals].se) / 2;

  % Remember row number.
  @#.fromlist.rownr[@#.fromlist.nquals] := row;

  % Arrow end points.
  @#.fromlist.qual[@#.fromlist.nquals].lend =
    l.col[cl].sw + (.5l.colwidth[cl], 0);
  @#.fromlist.qual[@#.fromlist.nquals].rend =
    r.col[cr].sw + (.5r.colwidth[cr], 0);

  @#.fromlist.nquals := incr(@#.fromlist.nquals);
enddef;

def drawwherequals(text q) =
  numeric i;

  % Draw arrows first - it'd be disturbing if they crossed the qual boxes.

  for i=0 upto q.fromlist.nquals - 1:
    % Qualifier
    drawopbox(q.fromlist.qual[i]);

    drawlabel(q.fromlist.qual[i]);

    % Arrows to the referenced columns.
    pickup arrowpen;
    drawarrow q.fromlist.qual[i].w{left}...{up}q.fromlist.qual[i].lend;
    drawarrow q.fromlist.qual[i].e{right}...{up}q.fromlist.qual[i].rend;
  endfor;
enddef;

def createquery(text q) =
  % WHERE qualifiers which don't reference 2 tables, or can't be positioned
  % automatically.
  picture q.loosequal[];
  pair q.loosequal[].n, q.loosequal[].w, q.loosequal[].s, q.loosequal[].e, q.loosequal[].nw, q.loosequal[].sw, q.loosequal[].se, q.loosequal[].ne;
  numeric q.nloosequals;

  % Constants.
  picture q.const[];
  pair q.const[].n, q.const[].w, q.const[].s, q.const[].e, q.const[].nw, q.const[].sw, q.const[].se, q.const[].ne;
  numeric q.nconsts;

  createrte(q);
  createfromlist(q);

  q.kind := "q";
  q.nloosequals := 0;
  q.nconsts := 0;
enddef;

% Add WHERE qualifier, position of which must be explicitly given in the
% picture source code.
vardef addloosewherequal@#(text oppic) =
  finalizequal(@#.loosequal[@#.nloosequals])(oppic);
  @#.loosequal[@#.nloosequals] := oppic;
  @#.nloosequals := incr(@#.nloosequals);
enddef;

def drawloosewherequals(text q) =
  numeric i;

  % Draw arrows first - it'd be disturbing if they crossed the qual boxes.

  for i=0 upto q.nloosequals - 1:
    drawopbox(q.loosequal[i]);
    drawlabel(q.loosequal[i]);
  endfor;
enddef;

% XXX This is similar to finalizequal(). Does it make sense to make that macro
% more generic?
def finalizeconst(text q, oppic) =
  q := oppic;
  q.nw + (getcolwidth(oppic), 0) = q.ne;
  q.sw + (getcolwidth(oppic), 0) = q.se;
  q.ne - (0, colheight) = q.se;
  q.nw - (0, colheight) = q.sw;
  q.n = 0.5[q.ne, q.nw];
  q.s = 0.5[q.se, q.sw];
  q.w = 0.5[q.nw, q.sw];
  q.e = 0.5[q.ne, q.se];
enddef;

% Add a box that represents constant expression.
vardef addconst@#(text valuepic) =
  finalizeconst(@#.const[@#.nconsts])(valuepic);

  @#.const[@#.nconsts] := valuepic;
  @#.nconsts := incr(@#.nconsts);
enddef;

def drawconst(text c) =
    p := c.sw--c.se--c.ne--c.nw--cycle;
    fill p withcolor constboxbgcolor;
    draw p;
enddef;

def drawconsts(text q) =
  numeric i;

  for i=0 upto q.nconsts - 1:
    pickup oppen;
    drawconst(q.const[i]);

    drawlabel(q.const[i]);
  endfor;
enddef;

% Color overview table.
pair	co_row[].nw, co_row[].sw, co_row[].se, co_row[].ne;
picture	co_row[];
color	co_box_color[];
numeric	co_rows;
pair	color_overview.sw;

def addcoloroverviewrow(text t, c) =
  co_row[co_rows] := TEX gettexstr(t);
  co_box_color[co_rows] := c;
  co_rows := incr(co_rows);
enddef;

def createcoloroverview =
  co_rows := 0;
  setfntstr := "\font\fntcmr = cmr7 \fntcmr ";
  colheight := 14pt;
  colminwidth := 12pt;
  addcoloroverviewrow("Query")(querybgcolor[0]);
  addcoloroverviewrow("FROM list")(fromlistbgcolor);
  addcoloroverviewrow("Table")(tablebgcolor);
  addcoloroverviewrow("Column")(defcolbgcolor);
  %addcoloroverviewrow("Output Column")(outcolbgcolor);
  addcoloroverviewrow("Constant")(constboxbgcolor);
  addcoloroverviewrow("Operator")(opboxbgcolor);
enddef;

% Generate equations for color overview, with given south-west corner.
def finalizecoloroverview(text _sw) =
  numeric i, width, maxwidth;

  maxwidth := 0;
  for i=0 upto co_rows - 1:
    width := xpart(lrcorner co_row[i] - llcorner co_row[i]);
    maxwidth := max(width, maxwidth);
  endfor;

  width := maxwidth + colminwidth;

  for i=0 upto co_rows - 1:
    if i = co_rows - 1:
      % The last row.
      co_row[i].sw = color_overview.sw;
    else:
      co_row[i].sw = co_row[i + 1].nw;
    fi;

    co_row[i].se = co_row[i].sw + (width, 0);
    co_row[i].nw = co_row[i].sw + (0, colheight);
    xpart co_row[i].ne = xpart co_row[i].se;
    ypart co_row[i].ne = ypart co_row[i].nw;
  endfor;

  co_row[co_rows - 1].sw = _sw;
enddef;

def drawcoloroverview =
  numeric i;
  path co_box;

  pickup colpen;
  for i=0 upto co_rows - 1:
    % The label.
    draw co_row[i].sw--co_row[i].se--co_row[i].ne--co_row[i].nw--cycle;
    draw co_row[i] shifted (co_row[i].sw + (.5colminwidth, labelbordery));

    % The color box should be square, so use colheight for both dimensions.
    co_box := co_row[i].se--co_row[i].se + (colheight, 0)--co_row[i].ne +
      (colheight, 0)--co_row[i].ne--cycle;
    fill co_box withcolor co_box_color[i];
    draw co_box;
  endfor;
enddef;
