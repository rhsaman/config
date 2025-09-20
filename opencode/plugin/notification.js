export const NotificationPlugin = async ({
  project,
  client,
  $,
  directory,
  worktree,
}) => {
  return {
    event: async ({ event }) => {
      // Play alert sound on session completion
      if (event.type === "session.idle") {
        await $`afplay /Users/saman/Music/alert.mp3 2>/dev/null`;
      }
      // Play sound when permission is asked
      if (event.type === "permission.updated") {
        await $`afplay /Users/saman/Music/error.mp3 2>/dev/null`;
      }
    },
  };
};
