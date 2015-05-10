visibility(1).
visit_points(0).
substep(0).
last_move(blank).
free.

// init
!start.
+!start : .my_name(Name) & grid_size(X, Y) & visibility(C) & friend(F1) & friend(F2) & (F1 \== F2) <-
	.send(F1, tell, fast_agent(Name));
	.send(F2, tell, fast_agent(Name));
	A = math.floor((X-1)/(2*C+1)) + 1;
	B = math.floor((Y-1)/(2*C+1)) + 1;
	D = A*B;
	+max_visit_points(D).


+step(X) <- -move_on;-picking;!inform_friends;!action;!inform_friends;!action;!inform_friends;!action.

+substep(1): pos(PosX, PosY) & middle_agent(Name) <-
	.print("Stalkuj me");	
	.send(Name, tell, fastAgentIsAt(PosX, PosY));
.
+was_on(A,B,X): was_on(C,D,Y) & ((X - Y) = 4) & middle_agent(Name) <-
	.print("Stalkuj me");	
	.send(Name, tell, fastAgentIsAt(C,D));
.

+!find_cell_to_explore : grid_size(GridX, GridY) & pos(PosX,PosY) & visibility(C)<-
	for( .range(CntX,C,GridX-1) ) {
		for( .range(CntY,C,GridY-1) ) {
			if( not destination(_,_)) {
				A = CntX;
				B = CntY;
				if (((CntX mod (2*C+1)) == C) & ((CntY mod (2*C+1)) == C) & not(visited_point(A,B))) {
					+destination(A,B);
					+visited_point(A,B);
					W = V + 1;
					-visit_points(V);+visit_points(W)
				}
			}
		}	
	}
.

calc_distance(PosX,PosY,X,Y,D) :- D = math.abs(PosX - X) + math.abs(PosY-Y).

find_nearest_gold(D,PosX,PosY,X,Y) :- found(gold,X,Y) & calc_distance(PosX,PosY,X,Y,D).
find_nearest_wood(D,PosX,PosY,X,Y) :- found(wood,X,Y) & calc_distance(PosX,PosY,X,Y,D).

//init
+!action: not slow_agent(_) | not middle_agent(_) <- !action.

+!action : moves_left(0) <- true.

// prave doslo k vyzvednuti => musim prenest suroviny
+!action: ( not carrying_gold(0) | not carrying_wood(0)) & not move_on  <- !action.

// vyzvednuti s jinym agentem
+!action: pos(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & ally(DX,DY) & step(S) & pick_in(S) <-
	.print("nakladam surovinu");
	do(pick);
	-pick_in(S);
	-found(gold,DX,DY);
	-found(wood,DX,DY);
	-gold(DX,DY);
	-wood(DX,DY);
	.abolish(destination(_,_));
	+wait_for_transfer;
	.print("surovina nalozena").
	
// cekani na dalsiho agenta
+!action: pos(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & not ally(DX,DY) & middle_agent(Name) <-
	.print("ale cekam na kolegu1");
	if(not(middleAgentComing(DX,DY))) { .send(Name, achieve, update_target(DX,DY)); }
	do(skip).
	
+!action: pos(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & moves_per_round(M) & not moves_left(M) & middle_agent(Name) <-
	.print("ale cekam na kolegu2");
	if(not(middleAgentComing(DX,DY))) { .send(Name, achieve, update_target(DX,DY)); }
	do(skip).
	
// tady uz nic neni
+!action: pos(DX,DY) & destination(DX,DY) & ( found(gold,DX,DY) | found(wood,DX,DY) ) & not gold(DX,DY) & not wood(DX,DY) & slow_agent(F1) & middle_agent(F2) <-
	.print("tady uz nic neni");
	.abolish(found(gold,DX,DY));
	.abolish(found(wood,DX,DY));
	.send(F1, untell, found(gold,DX,DY));
	.send(F2, untell, found(gold,DX,DY));
	.send(F1, untell, found(wood,DX,DY));
	.send(F2, untell, found(wood,DX,DY));
	-destination(DX,DY);
	!action.

+!action: destination(DX,DY) & pos(DX,DY) & (gold(DX,DY) | wood(DX,DY)) & depot(DepX, DepY) & middle_agent(Name) <-
	.print("jsem na policku se surovinou");
	if(not(middleAgentComing(DX,DY))) { .send(Name, achieve, update_target(DepX, DepY)); }
	do(skip);
.
	
// nasel jsem blizsi zlato
+!action: destination(DX,DY) & pos(PosX,PosY) & found(gold,GX,GY) & (DX \== GX | DY \== GY) & calc_distance(PosX,PosY,DX,DY,D) & calc_distance(PosX,PosY,GX,GY,G) & G < D & middle_agent(Name) <-
	.print("nasel jsem blizsi cil");
	.abolish(destination(_,_));
	+destination(GX,GY);
	if(not(middleAgentComing(GX,GY))) { .send(Name, achieve, update_target(GX,GY)); } 
	!action.
	
// nasel jsem blizsi drevo
+!action: destination(DX,DY) & pos(PosX,PosY) & found(wood,GX,GY) & (DX \== GX | DY \== GY) & calc_distance(PosX,PosY,DX,DY,D) & calc_distance(PosX,PosY,GX,GY,G) & G < D & middle_agent(Name) <-
	.print("nasel jsem blizsi cil");
	.abolish(destination(_,_));
	+destination(GX,GY);
	.send(Name, achieve, update_target(GX,GY));
	if(not(middleAgentComing(GX,GY))) { .send(Name, achieve, update_target(GX,GY)); } 
	!action.

// jsem na miste prohledani
+!action: destination(DX,DY) & pos(DX,DY) <-
	.print("uz jsem tu...");  
	.abolish(was_on(_,_,_));
	.abolish(destination(_,_));
	!find_cell_to_explore;
	!action.
// novy cil - zlato
+!action: not destination(_,_) & found(gold,_,_) & pos(PosX,PosY)  <-
	.findall(D,(found(gold,A,B) & calc_distance(PosX,PosY,A,B,D)),Distances);
	.min(Distances,Min);
	?find_nearest_gold(Min,PosX,PosY,A,B);
	+destination(A,B);
	.print("zmena cile -> zlato na pozici ", A, ", ", B);
	!action.
// novy cil - drevo
+!action: not destination(_,_) & found(wood,_,_) & pos(PosX,PosY)  <-
	.findall(D,(found(wood,A,B) & calc_distance(PosX,PosY,A,B,D)),Distances);
	.min(Distances,Min);
	?find_nearest_wood(Min,PosX,PosY,A,B);
	+destination(A,B);
	.print("zmena cile -> wood na pozici ", A, ", ", B);
	!action.
// novy cil - prohledavani mapy
+!action: not destination(_,_) & visit_points(V) & max_visit_points(W) & V < W <-
	!find_cell_to_explore;
	!action.
// mapa prohledana, suroviny posbirany
+!action: visit_points(V) & max_visit_points(V) & not destination(_,_) & not found(gold,_,_) & not found(wood,_,_) <-
	.print("KONEC");
	do(skip).
// pohyb

+!action : not moves_left(0) & depot(DepX, DepY) & (not carrying_wood(0) | not carrying_gold(0)) <-
	!goSomewhere(DepX,DepY);
	.print("Pujdu do depa");
	+visited_point(X,Y).

+!action : not moves_left(0) & destination(X,Y) <-
	!goSomewhere(X,Y);
	.print("Pujdu do ", X, ", ", Y);
	+visited_point(X,Y).

+!action <- true.
 
+!doMove(Direction): substep(S) & pos(PosX, PosY) & friend(F1) & friend(F2) & (F1 \== F2) & grid_size(GridX, GridY) & visibility(V) <-
	-substep(S); +substep(S + 1);
	.abolish(last_move(_));
	+last_move(Direction);
	do(Direction);
	
	for( .range(CntX,-V,V) ) {
		for( .range(CntY,-V,V) ) {
			if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
				A = PosX + CntX; B = PosY + CntY;
				+explored(PosX + CntX, PosY + CntY);
				.send(F1, tell, explored(A,B));
				.send(F2, tell, explored(A,B));
			}
		}
	}
.

+!goSomewhere(X,Y): moves_per_round(0) <- true.
+!goSomewhere(X,Y) <-
	!getMovement(X,Y); !goToSpecificPoint(X,Y);
.
/*
+!getMovement(X,Y): not free & pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) <-
	.abolish(can_go(_));
	+was_on(PosX, PosY, Step);
	if (not(obstacle(PosX + 1, PosY)) & ((PosX + 1) < GridX) & not last_move(left))
		{ +can_go(right) }
	if(not(obstacle(PosX - 1, PosY)) & ((PosX - 1) >= 0   ) & not last_move(right))
		{ +can_go(left) } 
	if(not(obstacle(PosX, PosY + 1)) & ((PosY + 1) < GridY) & not last_move(up))
		{ +can_go(down) } 
	if(not(obstacle(PosX, PosY - 1)) & ((PosY - 1) >= 0   ) & not last_move(down))
		{ +can_go(up) } 
.
*/
+!getMovement(X,Y): pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) <-
	.abolish(can_go(_));
	+was_on(PosX, PosY, Step);
	if(not(obstacle(PosX + 1, PosY)) & ((PosX + 1) < GridX) & not(was_on(PosX + 1, PosY, _)))
		{ +can_go(right) }
	if(not(obstacle(PosX - 1, PosY)) & ((PosX - 1) >= 0   ) & not(was_on(PosX - 1, PosY, _)))
		{ +can_go(left) } 
	if(not(obstacle(PosX, PosY + 1)) & ((PosY + 1) < GridY) & not(was_on(PosX, PosY + 1, _)))
		{ +can_go(down) } 
	if(not(obstacle(PosX, PosY - 1)) & ((PosY - 1) >= 0   ) & not(was_on(PosX, PosY - 1, _)))
		{ +can_go(up) } 
.

+!goToSpecificPoint(X,Y): grid_size(GridX, GridY) & substep(NowStep) & pos(PosX,PosY) 
	& was_on(PosX,PosY, PrevStep) & was_on(PosX,PosY, PrevPrevStep) & ((NowStep - PrevStep) > 4) 
	& ((PrevStep - PrevPrevStep) > 4) & ((NowStep - PrevStep) == (PrevStep - PrevPrevStep)) & not(free)  <-
	.print("SHIT");
	//!getMovement(X,Y);
	if(PosX = (GridX - 1)) { !doMove(left); }
	if(PosX = 0) {!doMove(right); }
	if(PosY = (GridY - 1))  { !doMove(up); }
	if(PosY = 0) { !doMove(down); }
	else { +free; !getMovement(X,Y); !goToSpecificPoint(X,Y); }
.
+!goToSpecificPoint(_,_): moves_left(0) <- true.

+!goToSpecificPoint(X,Y): pos(X,Y) & step(S) & fast_agent(Name) & (not carrying_gold(0) & not carrying_wood(0)) <-
	.print("Synchro with fast");
	SS = S+1;
	.send(Name, tell, pick_in(SS));
	-goSomewhere(X, Y);
	.abolish(was_on(_,_,_));
	!action.
	
+!goToSpecificPoint(X,Y): pos(X, Y) & (not carrying_gold(0) | not carrying_wood(0)) & depot(DX, DY) & fast_agent(Name) <-
	.print("Done! Returning to Depot...");
	-goSomewhere(X, Y);
	+goSomewhere(DX, DY);
	.abolish(was_on(_,_,_));
	.send(Name, tell, middleAgentComing(DX,DY));
	.send(Name, untell, middleAgentComing(X,Y));
	!action.

+!goToSpecificPoint(X,Y) : pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) &
	not(can_go(left)) & not(can_go(right)) & not(can_go(up)) & not(can_go(down)) & not(returning(_)) <-
	.abolish(returning(_));
	+returning(Step - 1);
	.print("I AM STUCK");
	!goToSpecificPoint(X,Y);
.

+!goToSpecificPoint(X,Y) : pos(PosX, PosY) & grid_size(GridX, GridY) & returning(BackStep) & substep(NowStep) &
	was_on(GoToX, GoToY, BackStep) & not can_go(left) & not can_go(right) & not can_go(up) & not can_go(down) <-
	
	-substep(NowStep); +substep(NowStep + 1);
	-returning(BackStep); +returning(BackStep - 1);
	if(PosX > GoToX) { !doMove(left); }
	if(PosX < GoToX) { !doMove(right); }
	if(PosY > GoToY) { !doMove(up); }
	if(PosY < GoToY) { !doMove(down); }
.

// ***************  DEFAULT MOVEMENT *****************
// up -> right -> left -> down
// UP + LEFT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(left,down,up,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(up,right,left,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y)                    <- -free; .abolish(returning(_)); !moveOrder(up,left,right,down).

// DOWN + LEFT	
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(left,up,down,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(down,right,left,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y)                    <- -free; .abolish(returning(_)); !moveOrder(down,left,right,up).

// UP + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(right,down,up,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(up,left,right,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y)                    <- -free; .abolish(returning(_)); !moveOrder(up,right,left,down).

// DOWN + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(right,up,down,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(down,left,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y)                    <- -free; .abolish(returning(_)); !moveOrder(down,right,left,up).

// UP
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(right,left,down,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(left)  <- +free; .abolish(returning(_)); !moveOrder(up,left,down,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(up,right,down,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) 				   <- +free; .abolish(returning(_)); !moveOrder(up,right,left,down).

// DOWN
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(right,left,up,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(down,left,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(down,right,up,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) 				   <- +free; .abolish(returning(_)); !moveOrder(down,left,right,up).

// RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(left)  <- -free; .abolish(returning(_)); !moveOrder(up,down,left,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(right,up,left,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(right,down,left,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) 				   <- +free; .abolish(returning(_)); !moveOrder(right,up,down,left).

// LEFT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(right) <- -free; .abolish(returning(_)); !moveOrder(up,down,right,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(up)    <- -free; .abolish(returning(_)); !moveOrder(left,up,right,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(down)  <- -free; .abolish(returning(_)); !moveOrder(left,down,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) 				   <- +free; .abolish(returning(_)); !moveOrder(left,up,down,right).

+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY = Y) 				   <- .abolish(returning(_)); .abolish(goSomewhere(_,_)).

+!moveOrder(D,_,_,_): can_go(D) <- !doMove(D).
+!moveOrder(_,D,_,_): can_go(D) <- !doMove(D).
+!moveOrder(_,_,D,_): can_go(D) <- !doMove(D).
+!moveOrder(_,_,_,D): can_go(D) <- !doMove(D).

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
+!inform_friends <- !inform_friends.

+gold(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(gold,X,Y);
	.send(F1, tell, found(gold,X,Y));
	.send(F2, tell, found(gold,X,Y)).
+wood(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(wood,X,Y);
	.send(F1, tell, found(wood,X,Y));
	.send(F2, tell, found(wood,X,Y)).
