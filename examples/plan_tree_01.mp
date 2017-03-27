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

input TEX;
input "metapostgres/common";
input "metapostgres/table";
input "metapostgres/plan";

prologues := 3;

beginfig(0);
  createtable(2, 3);
  settablename("licenses");
  addheader("id");
  addheader("name");
  addheader("is\_copyleft")
  setcolalignments(r,l,l);
  setcolumn(1, 0, "1");
  setcolumn(1, 1, "GPL");
  setcolumn(1, 2, "true");
  setcolumn(2, 0, "2");
  setcolumn(2, 1, "BSD");
  setcolumn(2, 2, "false");

  createplannode("seqscan");
  setplanqual("is\_copyleft = true");

  % Table 1 is the scan result.
  derivetable(0)(1)(1);

  tables[0].sw = (0, 0);
  plannodes[0].result + (0, plannodespacing) = tables[1].s;

  finalizetable(0);
  finalizetable(1);
  finalizeplannode(0);

  attachsingleinput(plannodes[0])(tables[0]);

  initboundingbox(tables[0].nw)(tables[0].se);
  computescalefactor(metapg.bbox);

  adjusttablepens;
  adjustplanpens;

  drawtable(0);
  drawtable(1);
  drawplannode(0);

  drawsimpleplaninputarrow(plannodes[0])(tables[0]);
  drawplanoutputarrow(plannodes[0])(tables[1]);

  fixpicturewidth;
endfig;
end
