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

% TODO Colors

numeric tbcellspacingx, tbcellheight, tbrowspacing, tbheaderspacing,
  tbouterspacing;

% The minimum space between text and cell border.
tbcellspacingx := 6pt;

% Space between the bottom edge of cell and that of the label text.
cellspacingy := 2pt;

% Cell height.
tbcellheight := 18pt;

% Vertical space between rows.
tbrowspacing := 2pt;

% Vertical space between header and the first row.
tbheaderspacing := 6pt;

numeric	tables[].nrows, tables[].ncols;

% Table name (optional).
picture tables[].name;
pair tables[].name.nw, tables[].name.ne, tables[].name.sw, tables[].name.se;

% Cell contents. The 0-th row is header.
picture tables[].row[].col[];

% Space between table rows and the outer edge of the bounding box.
tbouterspacing := 8pt;

% Corners of the table bounding box respectively.
pair tables[].sw, tables[].se, tables[].ne, tables[].nw;

% The middle of the south, west, north and east edges.
pair tables[].s, tables[].w, tables[].n, tables[].e;

% Vertical distance of the south edge of a row from the south edge of the last
% row.
numeric tables[].row[].off;

% Per-column alignment (l = left, c = center, r = right).
string tables[].align[];

% Per-column width.
numeric tables[].width[];

% Total width of table row.
numeric tables[].rowwidth;

% Width of table row or label, whichever is bigger.
numeric tables[].maxrowwidth;

numeric currenttable, currentcolumn;
currenttable := -1;

numeric i, j;

pen tablepen;
numeric tablepenwidth;
tablepenwidth := 1;

color tablebgcolor, tablehdrcolor, tablecellcolor, tablelblcolor;

tablebgcolor := hexrgbcolor("F2")("ED")("87");
tablehdrcolor := hexrgbcolor("C2")("AD")("94");
tablecellcolor := hexrgbcolor("FF")("E3")("C2");
tablelblcolor := hexrgbcolor("C2")("AA")("6C");

def adjusttablepens =
  tablepen := pencircle scaled (tablepenwidth / metapg.scalefactor);
enddef;

def createtable(expr _nrows, _ncols) =
  currenttable := incr(currenttable);
  tables[currenttable].nrows := _nrows;
  tables[currenttable].ncols := _ncols;

  currentcolumn := 0;
enddef;

def setcolalignments(text t) =
  i := 0;

  forsuffixes a=t:
    tables[currenttable].align[i] := str a;
    i := incr(i);
  endfor;
enddef;

def settablename(text n) =
  tables[currenttable].name := TEX gettexstr(n);
enddef;

def setcolumn(expr _row, _col, l) =
  tables[currenttable].row[_row].col[_col] := TEX gettexstr(l);
enddef;

% Header labels should always exist, so we can init the pictures in simpler
% way.
def addheader(text t) =
  setcolumn(0, currentcolumn, t);
  currentcolumn := incr(currentcolumn);
enddef;

numeric cellwidth, cellwidthmax;

def finalizetable(suffix tidx) =
  numeric gap;

  tables.tidx.rowwidth := 0;

  % Find out the maximum width of each column.
  for i=0 upto tables.tidx.ncols - 1:
    tables.tidx.width[i] := 0;
    cellwidthmax := 0;

    for j=0 upto tables.tidx.nrows:
      if known tables.tidx.row[j].col[i]:
	cellwidth := xpart (lrcorner tables.tidx.row[j].col[i] -
	    llcorner tables.tidx.row[j].col[i]);
      else:
	cellwidth := 0;
      fi;

      cellwidthmax := max(cellwidthmax, cellwidth);
    endfor;

    tables.tidx.width[i] := cellwidthmax + 2tbcellspacingx;
    tables.tidx.rowwidth := tables.tidx.rowwidth + cellwidthmax +
      2tbcellspacingx;
  endfor;

  % Define equations for rows.
  for i=0 upto tables.tidx.nrows:
    if i < tables.tidx.nrows:
      if i > 0:
	gap := tbrowspacing;
      else:
	gap := tbheaderspacing;
      fi;

      tables.tidx.row[i].off = tables.tidx.row[i + 1].off + tbcellheight + gap;
    else:
      % The last row.
      if known tables.tidx.name:
	% 1 spacing unit below the table name and 2 above it.
	tables.tidx.row[i].off = tbcellheight + 3tbouterspacing;
      else:
	tables.tidx.row[i].off = 0;
      fi;
    fi;
  endfor;

  if known tables.tidx.name:
    tables.tidx.name.sw = tables.tidx.sw + (tbouterspacing, tbouterspacing);
    finalizelabel(tables.tidx.name);
  fi;

  tables.tidx.maxrowwidth := tables.tidx.rowwidth;

  if known tables.tidx.name:
    tables.tidx.maxrowwidth := max(tables.tidx.maxrowwidth,
	xpart(tables.tidx.name.se - tables.tidx.name.sw));
  fi;

  % Equations for the outer box.
  tables.tidx.se = tables.tidx.sw + (tables.tidx.maxrowwidth +
      2tbouterspacing, 0);
  tables.tidx.nw = tables.tidx.sw + (0, tables.tidx.row[0].off + tbcellheight +
      2tbouterspacing);
  xpart tables.tidx.ne = xpart tables.tidx.se;
  ypart tables.tidx.ne = ypart tables.tidx.nw;

  % Middle points of edges.
  tables.tidx.s = 0.5[tables.tidx.se, tables.tidx.sw];
  tables.tidx.n = 0.5[tables.tidx.ne, tables.tidx.nw];
  tables.tidx.e = 0.5[tables.tidx.se, tables.tidx.ne];
  tables.tidx.w = 0.5[tables.tidx.sw, tables.tidx.nw];
enddef;

def drawtable(suffix tidx) =
  pair cell_sw, cell_swnext;
  numeric rowwidth, cellwidth, cell_w, cell_width, text_width;
  picture celltext;
  pair	cellshift;
  numeric cellshiftx;
  path	pth;

  pickup tablepen;

  % Bounding box of the table.
  pth := tables.tidx.sw--tables.tidx.nw--tables.tidx.ne--tables.tidx.se--
    cycle;
  draw pth;
  fill pth withcolor tablebgcolor;

  rowwidth := 0;
  for i=0 upto tables.tidx.ncols - 1:
    rowwidth := rowwidth + tables.tidx.width[i];
  endfor;

  for i=0 upto tables.tidx.nrows:
    % South-west corner of the current cell.
    cell_sw := tables.tidx.sw +
      (tbouterspacing, tbouterspacing + tables.tidx.row[i].off);

    for j=0 upto tables.tidx.ncols - 1:
      cellwidth := tables.tidx.width[j];
      cell_swnext := cell_sw + (cellwidth, 0);

      pth := cell_sw--cell_swnext--cell_swnext + (0, tbcellheight)--
	cell_sw + (0, tbcellheight)--cycle;
      draw pth;

      if i = 0:
	fill pth withcolor tablehdrcolor;
      else:
	fill pth withcolor tablecellcolor;
      fi;

      cell_sw := cell_swnext;
    endfor;
  endfor;

  % Labels.
  for i=0 upto tables.tidx.nrows:
    % Western edge of the current cell.
    cell_w := xpart tables.tidx.sw + tbouterspacing;

    for j=0 upto tables.tidx.ncols - 1:
      cell_width := tables.tidx.width[j];

      if known tables.tidx.row[i].col[j]:
	celltext := tables.tidx.row[i].col[j];
	text_width := xpart (lrcorner celltext - llcorner celltext);

	% Header text is always centered.
	if (i = 0) or (tables.tidx.align[j] = "c"):
	  cellshiftx := cell_w + .5(cell_width - text_width);
	elseif tables.tidx.align[j] = "l":
	  cellshiftx := cell_w + tbcellspacingx;
	else:
	  % The text should be right-aligned..
	  cellshiftx := cell_w + (cell_width - text_width - tbcellspacingx);
	fi;

	cellshift := (cellshiftx,
	    ypart tables.tidx.sw + tbouterspacing + tables.tidx.row[i].off +
	    cellspacingy);
	draw celltext shifted cellshift;
      fi;
      cell_w := cell_w + cell_width;
    endfor;
  endfor;

  if known tables.tidx.name:
    pth := tables.tidx.name.sw--tables.tidx.name.nw--tables.tidx.name.ne--
      tables.tidx.name.se--cycle;
    draw pth;
    fill pth withcolor tablelblcolor;
    drawlabel(tables.tidx.name);
  fi;
enddef;

% Derive new table from existing one, by selecting specified rows and
% columns. Header is always included, so row zero refers to row nr. on of the
% source table. (Columns are 0-based, like those of the source table.)
def derivetable(suffix src)(text _rows)(text _cols) =
  numeric i, rowidx;

  currenttable := incr(currenttable);

  % Header.
  i := 0;
  forsuffixes c=_cols:
    tables[currenttable].row[0].col[i] := tables.src.row[0].col[c];
    tables[currenttable].align[i] := tables.src.align[c];
    i := incr(i);
  endfor;
  tables[currenttable].ncols := i;

  % Body.
  rowidx := 1;
  forsuffixes r=_rows:
    i := 0;
    forsuffixes c=_cols:
      tables[currenttable].row[rowidx].col[i] := tables.src.row[r].col[c];
      i := incr(i);
    endfor;
    rowidx := incr(rowidx);
  endfor;

  tables[currenttable].nrows := rowidx - 1;
enddef;

% Join specified rows and columns of right table to existing left table. The
% number of rows of both tables must match.
def jointables(suffix left, right)(text _rows)(text _cols) =
  numeric i, ncols_orig, rowidx;

  % Header.
  ncols_orig := tables.left.ncols;
  i := ncols_orig;
  forsuffixes c=_cols:
    tables.left.row[0].col[i] := tables.right.row[0].col[c];
    tables.left.align[i] := tables.right.align[c];
    i := incr(i);
  endfor;
  tables.left.ncols := i;

  % Body.
  rowidx := 1;
  forsuffixes r=_rows:
    i := ncols_orig;
    forsuffixes c=_cols:
      tables.left.row[rowidx].col[i] := tables.right.row[r].col[c];
      i := incr(i);
    endfor;
    rowidx := incr(rowidx);
  endfor;
enddef;
