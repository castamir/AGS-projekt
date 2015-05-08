
// beliefs

last_dir(right).
last_checked(null,null).
area(0,0,5,5).
free.


// init
!start.
+!start: pos(X,Y) & area(X1,Y1,X2,Y2) <-
	+destination(X2,Y1);
	-last_checked(_,_);	+last_checked(X,Y).
	
+step(A) <- !work.
	
// last area
calc_next_check(X2,Y1) :- area(X1,Y1,X2,Y2) & last_checked(X2,Y2) & last_dir(right).
calc_next_check(X1,Y1) :- area(X1,Y1,X2,Y2) & last_checked(X1,Y2) & last_dir(left).
// last in row
calc_next_check(X2,NY) :- area(_,_,X2,Y2) & last_checked(X2,LY) & last_dir(right) & LY < Y2 & NY = LY+1.
calc_next_check(X1,NY) :- area(X1,_,_,Y2) & last_checked(X1,LY) & last_dir(left)  & LY < Y2 & NY = LY+1.
// next row
calc_next_check(X2,LY) :- area(X1,_,X2,_) & last_checked(X1,LY) & last_dir(down).
calc_next_check(X1,LY) :- area(X1,_,X2,_) & last_checked(X2,LY) & last_dir(down).
// else
calc_next_check(NX,LY) :- last_checked(LX,LY) & not last_dir(left) & NX = LX+1.
calc_next_check(NX,LY) :- last_checked(LX,LY) & not last_dir(right)  & NX = LX-1.

// next direction and its position
calc_next_move(NX,PY,left)  :-  pos(PX,PY) & destination(DX,DY) & PX > DX & NX = PX-1.
calc_next_move(NX,PY,right) :-  pos(PX,PY) & destination(DX,DY) & PX < DX & NX = PX+1.
calc_next_move(PX,NY,up)    :-  pos(PX,PY) & destination(DX,DY) & PY > DY & NY = PY-1.
calc_next_move(PX,NY,down)  :-  pos(PX,PY) & destination(DX,DY) & PY < DY & NY = PY+1.



+!work: free & destination(X,Y) & pos(X,Y) <-
	?calc_next_check(DX,DY);
	-destination(_,_); +destination(DX,DY);
	?calc_next_move(NX,NY,D);
	-last_checked(_,_); +last_checked(NX,NY);
	-last_dir(_); +last_dir(D);
	do(D).
+!work: free <-
	?calc_next_move(NX,NY,D);
	-last_checked(_,_); +last_checked(NX,NY);
	-last_dir(_); +last_dir(D);
	do(D).

