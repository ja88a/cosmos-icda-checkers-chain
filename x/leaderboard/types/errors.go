package types

// DONTCOVER

import (
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

// x/leaderboard module sentinel errors
var (
	ErrSample               = sdkerrors.Register(ModuleName, 1100, "sample error")
	ErrInvalidPacketTimeout = sdkerrors.Register(ModuleName, 1500, "invalid packet timeout")
	ErrInvalidVersion       = sdkerrors.Register(ModuleName, 1501, "invalid version")
	ErrWinnerNotParseable      = sdkerrors.Register(ModuleName, 1118, "winner is not parseable: %s")
    ErrThereIsNoWinner         = sdkerrors.Register(ModuleName, 1119, "there is no winner")
    ErrInvalidDateAdded        = sdkerrors.Register(ModuleName, 1120, "dateAdded cannot be parsed: %s")
    ErrCannotAddToLeaderboard  = sdkerrors.Register(ModuleName, 1121, "cannot add to leaderboard: %s")
)
