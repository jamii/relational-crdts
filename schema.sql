drop table if exists edit;
create table edit(id integer, parent_id integer, character text);
insert into edit values (0, null, 'a');
insert into edit values (1, 0, 'b');
insert into edit values (2, 0, 'e');
insert into edit values (3, 1, 'c');
insert into edit values (4, 1, 'd');
insert into edit values (5, 2, 'f');
insert into edit values (6, 5, 'g');
insert into edit values (7, 5, 'h');
insert into edit values (8, 5, 'i');

select '---';
select 'sort by spine';

with recursive
  path(id, path, character) as (
    -- path for the root is just the root id
    select edit.id, edit.id, edit.character
    from edit
    where edit.parent_id is null
    union all
    -- path for child is path for parent plus child id
    select child.id, parent.path || ',' || child.id, child.character
    from edit as child, path as parent
    where child.parent_id = parent.id
  )
-- sort by path to get the correct character ordering
select * from path order by path.path;

select '---';
select 'prev by subquery';

select '---';
select 'prev by row_number';

drop view if exists prev;
create view prev(id, prev_id) as
-- number each sibling in id order
with child_position(id, position) as (
  select edit.id, row_number() over (partition by edit.parent_id order by edit.id)
  from edit
)
-- the number 1 siblings comes after their parents
select edit.id, edit.parent_id
from edit, child_position
where edit.id = child_position.id
and child_position.position = 1
union all
-- other siblings come after the sibling at the previous position
select child.id, sibling.id
from edit as child, child_position, child_position as sibling_position, edit as sibling
where child.id = child_position.id
and child_position.position - 1 = sibling_position.position
and sibling_position.id = sibling.id
and sibling.parent_id = child.parent_id;
select * from prev;

select '---';
select 'rightmost leaves';

drop view if exists rightmost_child;
create view rightmost_child(id, parent_id) as
    select max(id), edit.parent_id
    from edit
    where edit.parent_id is not null
    group by parent_id;
select * from rightmost_child;

select '---';

drop view if exists rightmost_leaf;
create view rightmost_leaf(id, leaf_id) as
with recursive rightmost_descendant(id, child_id) as (
    select id, id
    from edit
    union
    select parent.parent_id, child.child_id
    from rightmost_child as parent, rightmost_descendant as child
    where parent.id = child.id
)
select id, max(child_id) as leaf_id
from rightmost_descendant
group by id;
select * from rightmost_leaf;

select '---';
select 'prev_sibling';

drop view if exists prev_sibling;
create view prev_sibling(id, prev_id) as
select edit.id, (
    select max(sibling.id)
    from edit as sibling
    where edit.parent_id = sibling.parent_id
    and edit.id > sibling.id
) as prev_id
from edit
where prev_id is not null;
select * from prev_sibling;

select '---';

drop view if exists prev_edit;
create view prev_edit(id, prev_id) as
-- edits that have no prev siblings come after their parent
select edit.id, edit.parent_id
from edit
where not exists(
  select *
  from prev_sibling
  where prev_sibling.id = edit.id
)
union all
-- other edits come after the rightmost leaf of their prev sibling
select edit.id, rightmost_leaf.leaf_id
from edit, prev_sibling, rightmost_leaf
where edit.id = prev_sibling.id
and prev_sibling.prev_id = rightmost_leaf.id;
select * from prev_edit;

select '---';

with recursive position(id, position, character) as (
  -- root is at position 0
  select edit.id, 0, edit.character
  from edit
  where edit.parent_id is null
  union all
  -- every other edit comes after their prev edit
  select edit.id, position.position + 1, edit.character
  from edit, prev_edit, position
  where edit.id = prev_edit.id
  and prev_edit.prev_id = position.id
)
select *
from position
order by position.position;