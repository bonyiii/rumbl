defmodule Rumbl.VideoChannel do
  use Rumbl.Web, :channel

  def join("videos:" <> video_id, _params, socket) do
    #:timer.send_interval(3_000, :ping)
    { :ok, assign(socket, :video_id, video_id) }
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    #push socket, "ping", %{count: count}

    {:noreply, assign(socket, :count, count + 1)}
  end

  def handle_in("new_annotation", params, socket) do
    user = socket.assigns.current_user
    {video_id, _} = Integer.parse(socket.assigns.video_id)
    changeset =
    user
    |> Ecto.Model.build(:annotations, video_id: video_id)
    |> Rumbl.Annotation.changeset(params)

    case Repo.insert(changeset) do
      {:ok, annotation} ->
        broadcast! socket, "new_annotation", %{
          user: Rumbl.UserView.render("user.json", %{user: user}),
          body: annotation.body,
          at: annotation.at
        }
        {:reply, :ok, socket}
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
