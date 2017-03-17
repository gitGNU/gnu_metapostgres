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
  % Table 0 - the left table.
  createtable(2, 3);
  settablename("projects p");
  addheader("id");
  addheader("project");
  addheader("license\_id");
  setcolalignments(r,l,r);
  setcolumn(1, 0, "1");
  setcolumn(1, 1, "Redis");
  setcolumn(1, 2, "2");
  setcolumn(2, 0, "2");
  setcolumn(2, 1, "GNU");
  setcolumn(2, 2, "1");
  finalizetable(0);
  tables[0].ne + (2plannodespacing, 0) = tables[2].nw;

  % Plan 0 - scan of table 0.
  createplannode("seqscan");
  finalizeplannode(0);
  attachsingleinput(plannodes[0])(tables[0]);
  plannodes[0].result + (0, plannodespacing) = tables[1].s;

  % Table 1 - result of the left table scan.
  derivetable(0)(1,2)(1,2);
  finalizetable(1);

  % Table 2 - the right table.
  createtable(2, 2);
  settablename("licenses l");
  addheader("id");
  addheader("name");
  setcolalignments(r,l);
  setcolumn(1, 0, "1");
  setcolumn(1, 1, "GPL");
  setcolumn(2, 0, "2");
  setcolumn(2, 1, "BSD");
  finalizetable(2);
  tables[0].sw = (0, 0);

  % Plan 1 - scan of table 2.
  createplannode("seqscan");
  attachsingleinput(plannodes[1])(tables[2]);
  plannodes[1].result + (0, plannodespacing) = tables[3].s;
  finalizeplannode(1);

  % Table 3 - result of the right table scan.
  derivetable(2)(1,2)(0,1);
  finalizetable(3);

  % Plan 2 - join of tables 1 and 3.
  createplannode("join");
  setplanqual("p.license\_id = l.id");
  finalizeplannode(2);
  attachjoininputs(plannodes[2])(tables[1])(tables[3]);

  % Table 4 - result of the join.
  createtable(2, 2);
  addheader("project");
  addheader("license");
  setcolalignments(l,l);
  setcolumn(1, 0, "Redis");
  setcolumn(1, 1, "BSD");
  setcolumn(2, 0, "GNU");
  setcolumn(2, 1, "GPL");
  finalizetable(4);
  plannodes[2].result + (0, plannodespacing) = tables[4].s;

  initboundingbox((xpart tables[0].se, ypart plannodes[2].result))
    (tables[2].se);
  computescalefactor(metapg.bbox);
  adjusttablepens;
  adjustplanpens;

  drawtable(0);
  drawtable(1);
  drawplannode(0);
  drawsimpleplaninputarrow(plannodes[0])(tables[0]);
  drawplanoutputarrow(plannodes[0])(tables[1]);

  drawtable(2);
  drawplannode(1);
  drawtable(3);
  drawsimpleplaninputarrow(plannodes[1])(tables[2]);
  drawplanoutputarrow(plannodes[1])(tables[3]);

  drawplannode(2);
  drawtable(4);
  drawjoininputarrows(plannodes[2])(tables[1])(tables[3]);
  drawplanoutputarrow(plannodes[2])(tables[4]);

  fixpicturewidth;
endfig;
end
