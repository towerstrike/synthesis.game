from collections import defaultdict, deque
from typing import Dict, List, Set, Optional, Iterator, Tuple


class DependencyGraph:
    """Abstract dependency graph for build systems"""
    
    def __init__(self):
        self.nodes: Set[str] = set()
        self.edges: Dict[str, Set[str]] = defaultdict(set)
        self.reverse_edges: Dict[str, Set[str]] = defaultdict(set)
    
    def add_node(self, node: str) -> None:
        """Add a node to the graph"""
        self.nodes.add(node)
    
    def add_edge(self, from_node: str, to_node: str) -> None:
        """Add dependency edge: from_node depends on to_node"""
        self.add_node(from_node)
        self.add_node(to_node)
        self.edges[from_node].add(to_node)
        self.reverse_edges[to_node].add(from_node)
    
    def remove_node(self, node: str) -> None:
        """Remove node and all its edges"""
        if node not in self.nodes:
            return
        
        self.nodes.remove(node)
        
        # Remove outgoing edges
        for dep in self.edges[node]:
            self.reverse_edges[dep].discard(node)
        del self.edges[node]
        
        # Remove incoming edges
        for dependent in self.reverse_edges[node]:
            self.edges[dependent].discard(node)
        del self.reverse_edges[node]
    
    def get_dependencies(self, node: str) -> Set[str]:
        """Get direct dependencies of a node"""
        return self.edges.get(node, set()).copy()
    
    def get_dependents(self, node: str) -> Set[str]:
        """Get direct dependents of a node"""
        return self.reverse_edges.get(node, set()).copy()
    
    def has_cycle(self) -> bool:
        """Detect if graph has circular dependencies"""
        visited = set()
        rec_stack = set()
        
        def dfs(node: str) -> bool:
            visited.add(node)
            rec_stack.add(node)
            
            for dep in self.edges[node]:
                if dep not in visited:
                    if dfs(dep):
                        return True
                elif dep in rec_stack:
                    return True
            
            rec_stack.remove(node)
            return False
        
        for node in self.nodes:
            if node not in visited:
                if dfs(node):
                    return True
        
        return False
    
    def find_cycle(self) -> Optional[List[str]]:
        """Find a cycle if one exists"""
        visited = set()
        rec_stack = set()
        path = []
        
        def dfs(node: str) -> Optional[List[str]]:
            visited.add(node)
            rec_stack.add(node)
            path.append(node)
            
            for dep in self.edges[node]:
                if dep not in visited:
                    result = dfs(dep)
                    if result:
                        return result
                elif dep in rec_stack:
                    # Found cycle, return path from cycle start
                    cycle_start = path.index(dep)
                    return path[cycle_start:] + [dep]
            
            path.pop()
            rec_stack.remove(node)
            return None
        
        for node in self.nodes:
            if node not in visited:
                cycle = dfs(node)
                if cycle:
                    return cycle
        
        return None
    
    def topological_sort(self) -> List[str]:
        """Return topologically sorted list (build order)"""
        if self.has_cycle():
            raise ValueError(f"Cannot sort cyclic graph. Cycle: {self.find_cycle()}")
        
        in_degree = {node: len(self.edges[node]) for node in self.nodes}
        queue = deque([node for node, degree in in_degree.items() if degree == 0])
        result = []
        
        while queue:
            node = queue.popleft()
            result.append(node)
            
            for dependent in self.reverse_edges[node]:
                in_degree[dependent] -= 1
                if in_degree[dependent] == 0:
                    queue.append(dependent)
        
        return result
    
    def get_build_levels(self) -> List[List[str]]:
        """Return nodes grouped by build level (parallelizable)"""
        if self.has_cycle():
            raise ValueError(f"Cannot level cyclic graph. Cycle: {self.find_cycle()}")
        
        in_degree = {node: len(self.edges[node]) for node in self.nodes}
        levels = []
        
        while any(degree == 0 for degree in in_degree.values()):
            current_level = [node for node, degree in in_degree.items() if degree == 0]
            levels.append(current_level)
            
            for node in current_level:
                in_degree[node] = -1  # Mark as processed
                for dependent in self.reverse_edges[node]:
                    if in_degree[dependent] > 0:
                        in_degree[dependent] -= 1
        
        return levels
    
    def transitive_closure(self, node: str) -> Set[str]:
        """Get all transitive dependencies of a node"""
        visited = set()
        
        def dfs(current: str):
            for dep in self.edges[current]:
                if dep not in visited:
                    visited.add(dep)
                    dfs(dep)
        
        dfs(node)
        return visited
    
    def minimal_dependencies(self, node: str) -> Set[str]:
        """Get minimal set of direct dependencies (no transitive)"""
        all_deps = self.edges[node].copy()
        transitive = set()
        
        for dep in all_deps:
            transitive.update(self.transitive_closure(dep))
        
        return all_deps - transitive
    
    def __len__(self) -> int:
        return len(self.nodes)
    
    def __contains__(self, node: str) -> bool:
        return node in self.nodes
    
    def __iter__(self) -> Iterator[str]:
        return iter(self.nodes)
    
    def __repr__(self) -> str:
        return f"DependencyGraph(nodes={len(self.nodes)}, edges={sum(len(deps) for deps in self.edges.values())})"