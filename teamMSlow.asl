visibility(3).
visit_points(0).
substep(0).
last_move(blank).
max_visit_x_point(0).
max_visit_y_point(0).

// init
!start.
+!start : .my_name(Name) & grid_size(X, Y) & visibility(C) & friend(F1) & friend(F2) & (F1 \== F2) <-
	.send(F1, tell, slow_agent(Name));
	.send(F2, tell, slow_agent(Name));
	A = math.floor((X-1)/(2*C+1)) + 1;
	B = math.floor((Y-1)/(2*C+1)) + 1;
	D = A*B;
	+max_visit_points(D).
	


+step(X) : moves_left(0) <- true.
+step(X) <- !start_round.

+!start_round: middle_agent(Name) <-
	!inform_friends;!action;
	.send(Name, achieve, start_round).
+!start_round <- .wait(200);!start_round.

+!find_cell_to_explore : grid_size(GridX, GridY) & pos(PosX,PosY) & visibility(C) & visit_points(V) & max_visit_x_point(MVX) & max_visit_y_point(MVY) <-
	for( .range(CntX,C,GridX-1) ) {
		for( .range(CntY,C,GridY-1) ) {
			if( not destination(_,_)) {
				A = CntX;
				B = CntY;
				if (((CntX mod (2*C+1)) == C) & ((CntY mod (2*C+1)) == C) & not(visited_point(A,B))) {
					+destination(A,B);
					+visited_point(A,B);
					W = V + 1;
					-visit_points(V);+visit_points(W);
					-max_visit_x_point(MVX);-max_visit_y_point(MVY);
					.max([MVX,A],NewMVX);.max([MVY,B],NewMVY);
					+max_visit_x_point(NewMVX);+max_visit_y_point(NewMVY);
				}
			}
		}	
	}.
// next direction and its position


+!doMove(left):  substep(S) & pos(PosX, PosY) & ally(PosX-1, PosY) <- do(skip).
+!doMove(up):    substep(S) & pos(PosX, PosY) & ally(PosX, PosY-1) <- do(skip).
+!doMove(right): substep(S) & pos(PosX, PosY) & ally(PosX+1, PosY) <- do(skip).
+!doMove(down):  substep(S) & pos(PosX, PosY) & ally(PosX, PosY+1) <- do(skip).
+!doMove(Direction): substep(S) & pos(PosX, PosY) <-
	-substep(S); +substep(S + 1);
	.abolish(last_move(_));
	+last_move(Direction);
	do(Direction);
.

+!goSomewhere(X,Y): moves_per_round(1) <- !getMovement(X,Y); !goToSpecificPoint(X,Y).
/*
+!getMovement(X,Y):  not free & pos(PosX, PosY) & grid_size(GridX, GridY) & substep(Step) <-
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
	//!getMovement(X,Y);
	if(PosX = (GridX - 1)) { !doMove(left); }
	if(PosX = 0) {!doMove(right); }
	if(PosY = (GridY - 1))  { !doMove(up); }
	if(PosY = 0) { !doMove(down); }
	else { +free; !getMovement(X,Y); !goToSpecificPoint(X,Y); }
.

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
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y) & last_move(down)  <-  .abolish(returning(_)); !moveOrder(left,down,up,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y) & last_move(right) <-  .abolish(returning(_)); !moveOrder(up,right,left,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY > Y)                    <-  .abolish(returning(_)); !moveOrder(up,left,right,down).

// DOWN + LEFT	
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y) & last_move(up)    <-  .abolish(returning(_)); !moveOrder(left,up,down,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y) & last_move(right) <-  .abolish(returning(_)); !moveOrder(down,right,left,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY < Y)                    <-  .abolish(returning(_)); !moveOrder(down,left,right,up).

// UP + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y) & last_move(down)  <-  .abolish(returning(_)); !moveOrder(right,down,up,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y) & last_move(left)  <-  .abolish(returning(_)); !moveOrder(up,left,right,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY > Y)                    <-  .abolish(returning(_)); !moveOrder(up,right,left,down).

// DOWN + RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y) & last_move(up)    <-  .abolish(returning(_)); !moveOrder(right,up,down,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y) & last_move(left)  <-  .abolish(returning(_)); !moveOrder(down,left,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY < Y)                    <-  .abolish(returning(_)); !moveOrder(down,right,left,up).

// UP
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(down)  <-  .abolish(returning(_)); !moveOrder(right,left,down,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(left)  <- +free; .abolish(returning(_)); !moveOrder(up,left,down,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) & last_move(right) <-  .abolish(returning(_)); !moveOrder(up,right,down,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY > Y) 				   <- +free; .abolish(returning(_)); !moveOrder(up,right,left,down).

// DOWN
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(up)    <-  .abolish(returning(_)); !moveOrder(right,left,up,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(left)  <-  .abolish(returning(_)); !moveOrder(down,left,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) & last_move(right) <-  .abolish(returning(_)); !moveOrder(down,right,up,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX = X) & (PosY < Y) 				   <- +free; .abolish(returning(_)); !moveOrder(down,left,right,up).

// RIGHT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(left)  <-  .abolish(returning(_)); !moveOrder(up,down,left,right).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(up)    <-  .abolish(returning(_)); !moveOrder(right,up,left,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) & last_move(down)  <-  .abolish(returning(_)); !moveOrder(right,down,left,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX < X) & (PosY = Y) 				   <- +free; .abolish(returning(_)); !moveOrder(right,up,down,left).

// LEFT
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(right) <-  .abolish(returning(_)); !moveOrder(up,down,right,left).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(up)    <-  .abolish(returning(_)); !moveOrder(left,up,right,down).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) & last_move(down)  <-  .abolish(returning(_)); !moveOrder(left,down,right,up).
+!goToSpecificPoint(X,Y): pos(PosX, PosY) & (PosX > X) & (PosY = Y) 				   <- +free; .abolish(returning(_)); !moveOrder(left,up,down,right).

+!moveOrder(D,_,_,_): can_go(D) <- !doMove(D).
+!moveOrder(_,D,_,_): can_go(D) <- !doMove(D).
+!moveOrder(_,_,D,_): can_go(D) <- !doMove(D).
+!moveOrder(_,_,_,D): can_go(D) <- !doMove(D).


//init
+!action: not middle_agent(_) | not fast_agent(_) <- .wait(100);!action.

+!action: visit_points(V) & max_visit_points(V) & pos(MVX,VMY) & max_visit_x_point(MVX) & max_visit_y_point(VMY) <-
	//.print("KONEC");
	do(skip).
	
+!action: not destination(_,_) <-
	//.print("hledam novy cil");  
	.abolish(destination(_,_)); 
	!find_cell_to_explore;
	!action.                      
	
+!action: destination(DX,DY) & obstacle(DX,DY) & pos(PosX,PosY) <-
	//.print("Na cili je prekazka, seru na to");
	.abolish(destination(_,_));
	!find_cell_to_explore;
	!action;
	.abolish(was_on(_,_,_)).
	
+!action: destination(DX,DY) & pos(DX,DY) <-
	//.print("uz jsem tu...");  
	.abolish(destination(_,_));
	!find_cell_to_explore;
	!action;
	.abolish(was_on(_,_,_)).
	
+!action: destination(X,Y) <-
	!goSomewhere(X,Y).

@iflabel[atomic] +!inform_friends : visibility(C) & pos(PosX,PosY) & friend(F1) & friend(F2) & (F1 \== F2) & grid_size(GridX, GridY) <-
	for( .range(CntX,-C,C) ) {
		for( .range(CntY,-C,C) ) {
			if((PosX + CntX >= 0) & (PosY + CntY >= 0) & (PosX + CntX <= GridX) & (PosY + CntY <= GridY)) {
				A = PosX + CntX; B = PosY + CntY;
				+explored(A, B);
				.send(F1, tell, explored(A,B));
				.send(F2, tell, explored(A,B));
			}
		}	
	}.
+!inform_friends <- .wait(100);!inform_friends.

+gold(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(gold,X,Y);
	.send(F1, tell, found(gold,X,Y));
	.send(F2, tell, found(gold,X,Y)).
+wood(X,Y) : friend(F1) & friend(F2) & (F1 \== F2) <-
	+found(wood,X,Y);
	.send(F1, tell, found(wood,X,Y));
	.send(F2, tell, found(wood,X,Y)).
