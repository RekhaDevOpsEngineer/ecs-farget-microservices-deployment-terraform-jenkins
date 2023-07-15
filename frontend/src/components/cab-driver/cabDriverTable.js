import { useEffect, useState } from 'react';
import Box from '@mui/material/Box';
import Button from '@mui/material/Button';
import Container from '@mui/material/Container';
import Divider from '@mui/material/Divider';
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TablePagination from "@mui/material/TablePagination";
import TableRow from "@mui/material/TableRow";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import Avatar from '@mui/material/Avatar';
import { Link } from 'react-router-dom';
import { useNavigate } from 'react-router-dom';
import AssignDriverModal from './cabDriverAssignment';


const CabDriverTable = ({rows, columns}) => {
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(10);
    const [open, setOpen] = useState(false);
    const handleOpen = () => setOpen(true);
    const handleClose = () => setOpen(false);
    const handleChangePage = (event, newPage) => {
        setPage(newPage);
        };

      const handleChangeRowsPerPage = (event) => {
        setRowsPerPage(+event.target.value);
        setPage(0);
      };


    return(
        <>
            <Container>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 10 }}>
                    <Box><p className='list-header'>Cab-Driver List</p></Box>
                    <Box>
                        <Button component={Button} 
                            variant="outlined"
                            sx={{ color: 'black', width: 180, mt: 2.5 }}
                            className='card-button'
                            onClick={() => handleOpen()}
                            >
                            ASsign a Cab
                        </Button>
                    </Box>
                </Box>
                <AssignDriverModal open={open} handleClose={handleClose}/>
                <Divider />
                {
                        <Container>
                            <TableContainer
                                sx={{
                                maxHeight: 440,
                                "&::-webkit-scrollbar": {
                                    display: "none"
                                },
                                }}
                            >
                                <Table stickyHeader aria-label="">
                                <TableHead>
                                <TableRow>
                                    {columns.map((column) => (
                                        <TableCell
                                        key={column.id}
                                        align={column.align}
                                        style={{ minWidth: column.minWidth }}
                                        >
                                        {column.label}
                                        </TableCell>
                                    ))}
                                    </TableRow>
                                </TableHead>
                                <TableBody>
                                {rows
                                .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                                .map((row) => {
                                    return (
                                    <TableRow
                                        hover
                                        role="checkbox"
                                        tabIndex={-1}
                                        key={row.id}
                                        sx={{ "& td": { border: 0 } }}
                                    >
                                        {columns.map((column) => (
                                        <>
                                            <TableCell key={column.id} align={column.align}>
                                            {column.id === 'edit' ? (
                                                <>
                                                <Box>
                                                    <DeleteIcon sx={{ width: 50 }} />
                                                </Box>
                                                </>
                                            ) : (
                                                <>
                                                {
                                                    column.id === 'cab' ? (`${row['cabModel']} - ${row['cabRegistrationNumber']}`) : row[column.id]
                                                }
                                                </>
                                            )}
                                            </TableCell>
                                        </>
                                        ))}
                                    </TableRow>
                                    );
                                })}
                                </TableBody>
                                </Table>
                            </TableContainer>
                            <TablePagination
                                rowsPerPageOptions={[10, 25, 100]}
                                component="div"
                                count={rows.length}
                                rowsPerPage={rowsPerPage}
                                page={page}
                                onPageChange={handleChangePage}
                                onRowsPerPageChange={handleChangeRowsPerPage}
                            />
                        </Container>
                }
               
            </Container>
        </>
    )
}

export default CabDriverTable