#if defined _extendeddiscord_included
#endinput
#endif
#define _extendeddiscord_included

/*********************************************************
 * Log a message into logs/discord/errors.log
 *
 * @param format	Message to log
 * @noreturn
 *********************************************************/
native void ExtendedDiscord_LogError(const char[] format, any ...);

/*********************************************************
 * Get the link of Steam Avatar Profile
 *
 * @param iClient	Client index.
 * @param buffer	String buffer to store value.
 * @param maxlen	Size of the buffer to store value.
 * @return          True on success. False otherwise.
 *********************************************************/
native bool ExtendedDiscord_GetAvatarLink(int iClient, const char[] buffer, int maxlen);

/**
 * Called right after something is loged a discord error.
 *
 * @param sBuffer      Buffer to store the log message in.
 * @param maxlen       Size of the log buffer.
 * @noreturn
 */
forward void ExtendedDiscord_OnErrorLogged(char[] sBuffer, int maxlen);

public SharedPlugin __pl_extendeddiscord =
{
	name = "ExtendedDiscord",
	file = "Extended_Discord.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

public void __pl_extendeddiscord_SetNTVOptional()
{
	MarkNativeAsOptional("ExtendedDiscord_LogError");
	MarkNativeAsOptional("ExtendedDiscord_GetAvatarLink");
}