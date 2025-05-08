require 'gosu'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

MAP_WIDTH = 200
MAP_HEIGHT = 200
CELL_DIM = 20

class Cell
  attr_accessor :north, :south, :east, :west, :vacant, :visited, :on_path

  def initialize
    @north = @south = @east = @west = nil
    @vacant = false
    @visited = false
    @on_path = false
  end
end

class GameWindow < Gosu::Window
  def initialize
    super MAP_WIDTH, MAP_HEIGHT, false
    self.caption = "Map Creation"
    @path = nil

    @columns = Array.new(MAP_WIDTH / CELL_DIM) do
      Array.new(MAP_HEIGHT / CELL_DIM) { Cell.new }
    end

    connect_neighbors
  end

  def connect_neighbors
    x_cell_count = MAP_WIDTH / CELL_DIM
    y_cell_count = MAP_HEIGHT / CELL_DIM

    (0...x_cell_count).each do |x|
      (0...y_cell_count).each do |y|
        cell = @columns[x][y]
        cell.north = @columns[x][y - 1] if y > 0
        cell.south = @columns[x][y + 1] if y < y_cell_count - 1
        cell.west  = @columns[x - 1][y] if x > 0
        cell.east  = @columns[x + 1][y] if x < x_cell_count - 1
      end
    end
  end

  def needs_cursor?
    true
  end

  def mouse_over_cell(mouse_x, mouse_y)
    cell_x = (mouse_x / CELL_DIM).to_i
    cell_y = (mouse_y / CELL_DIM).to_i
    [cell_x, cell_y]
  end

  def search(cell_x, cell_y)
    cell = @columns[cell_x][cell_y]
    return nil unless cell.vacant && !cell.visited

    cell.visited = true

    if cell_x == (@columns.length - 1)
      return [[cell_x, cell_y]]
    end

    [[cell.north, cell_y - 1], [cell.south, cell_y + 1],
     [cell.east,  cell_y],     [cell.west,  cell_y]].each do |neighbor, new_y|
      next unless neighbor

      new_x = case neighbor
              when cell.north then cell_x
              when cell.south then cell_x
              when cell.east  then cell_x + 1
              when cell.west  then cell_x - 1
              end

      path = search(new_x, new_y)
      return [[cell_x, cell_y]] + path if path
    end

    nil
  end

  def button_down(id)
    cell_x, cell_y = mouse_over_cell(mouse_x, mouse_y)
    if id == Gosu::MsLeft
      @columns[cell_x][cell_y].vacant = true
    elsif id == Gosu::MsRight
      clear_path_and_visits
      if @columns[cell_x][cell_y].vacant
        @path = search(cell_x, cell_y)
      end
    end
  end

  def clear_path_and_visits
    @columns.each do |col|
      col.each do |cell|
        cell.visited = false
        cell.on_path = false
      end
    end
  end

  def walk(path)
    path.each do |cell_x, cell_y|
      @columns[cell_x][cell_y].on_path = true
    end
  end

  def update
    if @path
      walk(@path)
      @path = nil
    end
  end

  def draw
    (0...@columns.length).each do |x|
      (0...@columns[x].length).each do |y|
        cell = @columns[x][y]
        color = Gosu::Color::GREEN
        color = Gosu::Color::YELLOW if cell.vacant
        color = Gosu::Color::RED if cell.on_path
        Gosu.draw_rect(x * CELL_DIM, y * CELL_DIM, CELL_DIM - 1, CELL_DIM - 1, color, ZOrder::TOP)
      end
    end
  end
end

GameWindow.new.show
