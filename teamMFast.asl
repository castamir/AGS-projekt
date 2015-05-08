kamen(10,10).
kamen(20,20).
kamen(25,25).
visibility(3).

free.

// init
!start.
+!start : pos(X,Y)<-
	+kamen(1,1);
	+kamen(1,1);
	.print("Ma pozice je:", X, ", ", Y);
	.my_name(Name);.print("I am: ", Name);
	.findall(kamen(A,B),(kamen(A,B)),K);
	.length(K,KL);
	.print("Pocet kamenu: ", KL).


+step(X) <- !inform_friends;!action;!inform_friends;!action;!inform_friends;!action.

+!find_cell_to_explore(X,Y) : grid_size(GridX, GridY) & visibility(C)<-
	for( .range(CntX,0,GridX-1) ) {
		for( .range(CntY,0,GridY-1) ) {
			if( not destination(_,_) & not explored(CntX,CntY)) {
				+destination(CntX,CntY);
			}
		}	
	}.
// next direction and its position
calc_next_move(NX,PY,left)  :-  pos(PX,PY) & destination(DX,DY) & PX > DX & NX = PX-1.
calc_next_move(NX,PY,right) :-  pos(PX,PY) & destination(DX,DY) & PX < DX & NX = PX+1.
calc_next_move(PX,NY,up)    :-  pos(PX,PY) & destination(DX,DY) & PY > DY & NY = PY-1.
calc_next_move(PX,NY,down)  :-  pos(PX,PY) & destination(DX,DY) & PY < DY & NY = PY+1.



+!action: free & not destination(_,_) <- 
	!find_cell_to_explore(X,Y);
	-free;
	!action.
+!action: not free & not destination(_,_) <-
	.print("Uz neni kam jit..."); 
	do(skip).
+!action: destination(DX,DY) & exploded(DX,DY) <-
	.print("Uz neni kam jit...");  
	.abolish(destination(_,_));
	+free;
	!action.
+!action: destination(DX,DY) & pos(DX,DY) <-
	.print("uz jsem tu...");  
	.abolish(destination(_,_));
	+free;
	!action.
+!action <-
	?calc_next_move(X,Y,D);
	.print("Pujdu do ", X, ", ", Y);do(D).
 
+!inform_friends : visibility(C) & pos(PosX,PosY) & friend(F1) & friend(F2) & (F1 \== F2) & grid_size(GridX, GridY) <-
	for( .range(CntX,-C,C) ) {
		for( .range(CntY,-C,C) ) {
			if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
				A = PosX + CntX; B = PosY + CntY;
				+explored(PosX + CntX, PosY + CntY);
				.send(F1, tell, explored(A,B));
				.send(F2, tell, explored(A,B));
			}
		}	
	}.
	
