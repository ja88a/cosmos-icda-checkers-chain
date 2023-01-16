package keeper

import (
	"context"
	"strconv"

	"github.com/alice/checkers/x/checkers/rules"
	"github.com/alice/checkers/x/checkers/types"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

// Handling of the message Create New Game
func (k msgServer) CreateGame(goCtx context.Context, msg *types.MsgCreateGame) (*types.MsgCreateGameResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Build up the Game object
	// get the sytem info nextIndex from the keeper attached to msgServer
	systemInfo, found := k.Keeper.GetSystemInfo(ctx)
	if !found {
		panic("SystemInfo not found")
	}
	newIndex := strconv.FormatUint(systemInfo.NextId, 10)

	newGame := rules.New()
	storedGame := types.StoredGame{
		Index:       newIndex,
		Board:       newGame.String(),
		Turn:        rules.PieceStrings[newGame.Turn],
		Black:       msg.Black,
		Red:         msg.Red,
		MoveCount:   0,
		BeforeIndex: types.NoFifoIndex,
		AfterIndex:  types.NoFifoIndex,
		Deadline:    types.FormatDeadline(types.GetNextDeadline(ctx)),
		Winner:      rules.PieceStrings[rules.NO_PLAYER],
		Wager:       msg.Wager,
		Denom:       msg.Denom,
	}

	// Validate the game inputs
	err := storedGame.Validate()
	if err != nil {
		return nil, err
	}

	// Store in the Fifo at tail
	k.Keeper.SendToFifoTail(ctx, &storedGame, &systemInfo)

	// Store it
	k.Keeper.SetStoredGame(ctx, storedGame) //store
	systemInfo.NextId++                     // persist in memory
	k.Keeper.SetSystemInfo(ctx, systemInfo) // store

	ctx.GasMeter().ConsumeGas(types.CreateGameGas, "Create game")

	// Interact: emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(types.GameCreatedEventType,
			sdk.NewAttribute(types.GameCreatedEventCreator, msg.Creator),
			sdk.NewAttribute(types.GameCreatedEventGameIndex, newIndex),
			sdk.NewAttribute(types.GameCreatedEventBlack, msg.Black),
			sdk.NewAttribute(types.GameCreatedEventRed, msg.Red),
			sdk.NewAttribute(types.GameCreatedEventWager, strconv.FormatUint(msg.Wager, 10)),
			sdk.NewAttribute(types.GameCreatedEventDenom, msg.Denom),
		),
	)

	// Interact: inform about the index of the created game
	return &types.MsgCreateGameResponse{
		GameIndex: newIndex,
	}, nil
	// return &types.MsgCreateGameResponse{}, nil
}
