defmodule Adoptoposs.Submissions do
  @moduledoc """
  The Submissions context.
  """

  import Ecto.Query, warn: false

  alias Adoptoposs.Repo
  alias Adoptoposs.Network.Repository
  alias Adoptoposs.Accounts.User
  alias Adoptoposs.Tags.Tag
  alias Adoptoposs.Submissions.{Project, Policy}

  defdelegate authorize(action, user, params), to: Policy

  @doc """
  Returns the list of a user's projects.

  ## Examples

      iex> list_projects(%User{})
      [%Project{}, ...]

  """
  def list_projects(%User{id: id}) do
    Project
    |> where(user_id: ^id)
    |> order_by(desc: :id)
    |> preload([:user, :language, :interests])
    |> Repo.all()
  end

  @doc """
  Returns the list of projects.

  ## Examples

      iex> list_projects(limit: 2)
      [%Project{}, ...]

  """
  def list_projects(limit: limit) do
    Project
    |> limit(^limit)
    |> order_by(desc: :id)
    |> preload([:user, :language, :interests])
    |> Repo.all()
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(user, 1)
      %Project{}

      iex> get_project!(user, -1)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id, opts \\ []) do
    from(p in Project, preload: ^(opts[:preload] || []))
    |> Repo.get!(id)
  end

  @doc """
  Gets a single project by its uuid.

  Returns nil if the Project does not exist.

  ## Examples

      iex> get_project_by_uuid(user, "61900487-e6e3-4a3b-881f-e3fe5e2ca5f1")
      %Project{}

      iex> get_project_by_uuid(user, "no-existing")
      nil

  """
  def get_project_by_uuid(uuid, opts \\ []) do
    with {:ok, value} <- Ecto.UUID.cast(uuid) do
      from(p in Project,
        where: p.uuid == ^value,
        preload: ^(opts[:preload] || [])
      )
      |> Repo.one()
    else
      :error ->
        nil
    end
  end

  @doc """
  Gets a single project.

  Return nil if the Project does not exist for the given user.

  ## Examples

      iex> get_user_project(user, 1)
      %Project{}

      iex> get_user_project(user, -1)
      nil

  """
  def get_user_project(%User{} = user, id) do
    user
    |> Ecto.assoc(:projects)
    |> preload(:user)
    |> preload(interests: [:creator])
    |> Repo.get(id)
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%Repository{}, %{field: value})
      {:ok, %Project{}}

      iex> create_project(%Repository{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(%Repository{} = repository, attrs \\ %{}) do
    %Project{}
    |> Project.create_changeset(repository, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs \\ %{}) do
    project
    |> Project.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{source: %Project{}}

  """
  def change_project(%Project{} = project) do
    Project.update_changeset(project, %{})
  end

  @doc """
  Returns recommended projects of the given language for a user.

  Supported options are `:limit` and `:preload`

  ## Examples

      iex> list_recommended_projects(user, tag)
      [%Project{}, ...]

      iex> list_recommended_projects(user, tag, limit: 1)
      [%Project{}]

      iex> list_recommended_projects(user, tag, preload: :user)
      [%Project{user: %User{}}, ...]
  """
  def list_recommended_projects(%User{id: user_id}, %Tag{id: tag_id}, opts \\ []) do
    Repo.all(
      from p in Project,
        preload: ^(opts[:preload] || []),
        limit: ^opts[:limit],
        where: p.language_id == ^tag_id,
        where: p.user_id != ^user_id,
        where:
          fragment(
            "SELECT COUNT(*) FROM interests WHERE project_id = ? AND creator_id = ?",
            p.id,
            ^user_id
          ) == 0
    )
  end
end
