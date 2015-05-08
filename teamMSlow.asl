/*+step(1) <- do(transfer,aFast,1). //enemy agent => error , also not with myself!!!*/


+step(A) : moves_left(0).
+step(A) : true <- !work.


+!work: destination(X,Y) & pos(X,Y) <- do(skip).
+!work: destination(X,Y) <- !move.
+!work: true <-
	!to_depot;
	!move.

+!move: pos(X,Y) & destination(X,Y) <- -destination(X,Y).
+!move: pos(Px,Py) & destination(Dx,Dy) & Px > Dx <- do(left).
+!move: pos(Px,Py) & destination(Dx,Dy) & Px < Dx <- do(right).
+!move: pos(Px,Py) & destination(Dx,Dy) & Py > Dy <- do(top).
+!move: pos(Px,Py) & destination(Dx,Dy) & Py < Dy <- do(down).

+!to_depot: depot(X,Y) <- +destination(X,Y).
