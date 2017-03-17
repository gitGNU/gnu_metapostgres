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
input "metapostgres/query";

prologues := 3;

beginfig(0);
  createquery(qa);

  createjoin(qa.abcd);
  createjoin(qa.abcd.left);
  createjoin(qa.abcd.right);

  createtable(qa.abcd.left.left);
  settablename.qa.abcd.left.left("table\_1");
  addrtecols.qa.abcd.left.left("i", "j", "k");

  createtable(qa.abcd.left.right);
  settablename.qa.abcd.left.right("table\_2");
  addrtecols.qa.abcd.left.right("x", "y", "z");
  addjoinqual.qa.abcd.left(0)(0)(opeq);
  addjoinqual.qa.abcd.left(1)(1)(opeq);
  settablename.qa.abcd.left("join\_1");

  createtable(qa.abcd.right.left);
  settablename.qa.abcd.right.left("table\_3");
  addrtecols.qa.abcd.right.left("l", "m");

  createtable(qa.abcd.right.right);
  settablename.qa.abcd.right.right("table\_4");
  addrtecols.qa.abcd.right.right("u", "v", "w");
  addjoinqual.qa.abcd.right(0)(2)(opeq);
  settablename.qa.abcd.right("join\_2");

  settablename.qa.abcd("join\_3");
  addjoinqual.qa.abcd(3)(0)(opeq);

  createtable(qa.e);
  settablename.qa.e("table\_5");
  addrtecols.qa.e("o", "p", "q");

  createtable(qa.f);
  settablename.qa.f("table\_6");
  addrtecols.qa.f("r", "s");

  createtable(qa.g);
  settablename.qa.g("table\_7");
  addrtecols.qa.g("t", "u");

  createquery(subqa);
  settablename.subqa("subquery\_1");
  addrtecols.subqa("x23", "y", "z");

  createjoin(subqa.a);
  settablename.subqa.a("join\_1");
  createtable(subqa.a.left);
  settablename.subqa.a.left("table\_1");
  addrtecols.subqa.a.left("i", "j", "k");
  createtable(subqa.a.right);
  settablename.subqa.a.right("table\_2");
  addrtecols.subqa.a.right("l", "m26");
  addjoinqual.subqa.a(0)(1)(opeq);
  addfromitems.subqa(subqa.a);
  setqualheight(subqa.fromlist)(0);

  addfromitems.qa(qa.abcd, qa.e, qa.f, qa.g, subqa);
  setqualheight(qa.fromlist)(3);
  qa.g.upperqualheight := 0;

  qa.upperqualheight := 30;
  qa.sw = (0, 0);

  addrtecols.qa("x", "y", "z");
  setoutcols.qa(0, 2);
  finalizequery(qa);

  addwherequal.qa(qa.abcd)(1)(qa.e)(0)(0)(opeq);
  addwherequal.qa(qa.abcd)(0)(qa.e)(1)(1)(opeq);
  addwherequal.qa(qa.e)(0)(qa.f)(1)(0)(opeq);
  addwherequal.qa(qa.abcd)(1)(qa.f)(0)(2)(opeq);
  addwherequal.qa(qa.f)(1)(subqa)(0)(2)(opeq);

  setoutcols.subqa.a.right(0, 1);

  computescalefactor(qa);
  adjustquerypens;

  drawquery(qa);
  drawwherequals(qa);

  fixpicturewidth;
endfig;

end
