package keeper

import (
	"strconv"
	"context"

	"github.com/alice/checkers/x/checkers/types"
	"github.com/alice/checkers/x/checkers/rules"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

func (k msgServer) CreateGame(goCtx context.Context, msg *types.MsgCreateGame) (*types.MsgCreateGameResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Handling the message

	
	systemInfo, found := k.Keeper.GetSystemInfo(ctx)
	if !found {
		panic("SystemInfo not found")
	}
	newIndex := strconv.FormatUint(systemInfo.NextId, 10)

	newGame := rules.New()
	storedGame := types.StoredGame{
		Index: newIndex,
		Board: newGame.String(),
		Turn:  rules.PieceStrings[newGame.Turn],
		Black: msg.Black,
		Red:   msg.Red,
	}

	// Validate the input game
	err := storedGame.Validate()
	if err != nil {
		return nil, err
	}

	// Store it
	k.Keeper.SetStoredGame(ctx, storedGame) //store
	systemInfo.NextId++ // persist in memory
	k.Keeper.SetSystemInfo(ctx, systemInfo) // store

	// Interact
	return &types.MsgCreateGameResponse{
		GameIndex: newIndex,
	}, nil
	// return &types.MsgCreateGameResponse{}, nil
}
